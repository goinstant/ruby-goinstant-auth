#encoding: UTF-8
require 'openssl'
require 'base64'
require 'json'

module GoInstant
  module Auth

    def self.pad64(str)
      rem = str.size % 4
      if rem > 0 then
        str << ("=" * (4-rem))
      end
      return str
    end

    def self.encode64(str)
      return Base64.urlsafe_encode64(str).sub(/=+$/,'')
    end

    def self.decode64(str)
      str = str.gsub(/\s+/,'').tr('-_','+/').sub(/=+$/,'')
      return Base64.decode64(pad64(str))
    end

    def self.compact_decode(str)
      return JSON.parse(decode64(str))
    end

    def self.compact_encode(thing)
      return encode64(JSON.generate(thing))
    end

    class SignerError < StandardError
    end

    class Signer

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

      @@REQUIRED_CLAIMS = {
        :domain => :iss,
        :id => :sub,
        :display_name => :dn
      }

      @@OPTIONAL_CLAIMS = {
        :groups => :g
      }

      @@REQUIRED_GROUP_CLAIMS = {
        :id => :id,
        :display_name => :dn
      }

      def self.map_required_claims(claims, table, msg="missing required key: %s")
        table.each do |name,claimName|
          if !claims.has_key?(name) then
            raise SignerError.new(msg % name)
          end
          claims[claimName] = claims.delete(name)
        end
        return claims
      end

      def self.map_optional_claims(claims, table)
        table.each do |name,claimName|
          if claims.has_key?(name) then
            claims[claimName] = claims.delete(name)
          end
        end
        return claims
      end

      def sign(user_data, extra_headers={})
        if !user_data.is_a?(Hash) then
          raise SignerError.new('Signer#sign() requires a user_data Hash')
        end
        claims = user_data.clone
        Signer.map_required_claims(claims, @@REQUIRED_CLAIMS)
        Signer.map_optional_claims(claims, @@OPTIONAL_CLAIMS)
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
            Signer.map_required_claims(group, @@REQUIRED_GROUP_CLAIMS, msg)
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
