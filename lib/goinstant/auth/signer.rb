#encoding: UTF-8
require 'openssl'

module GoInstant
  module Auth
    class SignerError < StandardError
    end

    # Converts user-hashes into JWTs
    class Signer

      # Required user_data properties and their corresponding JWT claim name
      #
      REQUIRED_CLAIMS = {
        :domain => :iss,
        :id => :sub,
        :display_name => :dn
      }

      # Optional user_data properties and their corresponding JWT claim name
      #
      OPTIONAL_CLAIMS = {
        :groups => :g
      }

      # Required group properties and their corresponding JWT claim name
      #
      REQUIRED_GROUP_CLAIMS = {
        :id => :id,
        :display_name => :dn
      }

      # Create a Signer with a particular key
      #
      # @param secret_key [String] A base64 or base64url format string
      # representing the secret key for your GoInstant App.
      #
      def initialize(secret_key)
        if secret_key.nil? then
          raise TypeError.new('Signer requires key in base64url or base64 format')
        end

        @binary_key = Auth.decode64(secret_key)
        if !@binary_key or @binary_key == '' then
          raise TypeError.new('Signer requires key in base64url or base64 format')
        end

        if @binary_key.size < 32 then
          raise StandardError.new(
            'expected key length >= 32 bytes, got %d bytes' % @binary_key.size
          )
        end
      end

      # @api private
      def self.map_required_claims(claims, table, msg="missing required key: %s") # :nodoc:
        table.each do |name,claimName|
          if !claims.has_key?(name) then
            raise SignerError.new(msg % name)
          end
          claims[claimName] = claims.delete(name)
        end
        return claims
      end

      # @api private
      def self.map_optional_claims(claims, table)
        table.each do |name,claimName|
          if claims.has_key?(name) then
            claims[claimName] = claims.delete(name)
          end
        end
        return claims
      end

      # Create and sign a token for a user.
      #
      # @param user_data [String] A Hash containing properties about the user.
      # See README.md for a complete list of options.
      #
      # @param extra_headers [Hash={}] Optional, additional JWT headers to include.
      #
      # @return [String] a JWS Compact Serialization format-string representing this user.
      #
      def sign(user_data, extra_headers={})
        if !user_data.is_a?(Hash) then
          raise SignerError.new('Signer#sign() requires a user_data Hash')
        end
        claims = user_data.clone
        Signer.map_required_claims(claims, REQUIRED_CLAIMS)
        Signer.map_optional_claims(claims, OPTIONAL_CLAIMS)
        claims[:aud] = 'goinstant.net'

        if claims.has_key?(:g) then
          groups = claims[:g]
          if !groups.is_a?(Array) then
            raise SignerError.new('groups must be an Array')
          end
          i = 0
          claims[:g] = groups.map do |group|
            group = group.clone
            msg = "group #{i} missing required key: %s"
            i += 1
            Signer.map_required_claims(group, REQUIRED_GROUP_CLAIMS, msg)
          end
        else
          claims[:g] = []
        end

        headers = extra_headers.clone
        headers[:typ] = 'JWT'
        headers[:alg] = 'HS256'

        signing_input = '%s.%s' % [headers, claims].map{ |x| Auth.compact_encode(x) }
        sig = OpenSSL::HMAC::digest('SHA256', @binary_key, signing_input)
        return '%s.%s' % [ signing_input, Auth.encode64(sig) ]
      end

    end

  end
end
