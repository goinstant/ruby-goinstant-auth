require 'json'
require 'base64'
require_relative 'auth/signer'

# GoInstant Ruby Modules
module GoInstant

  # Authentication classes and functions for use with GoInstant
  module Auth

    # Pads base64 strings.
    # @param str [String]
    # @return [String] padded (extra '=' added to multiple of 4).
    def self.pad64(str)
      rem = str.size % 4
      if rem > 0 then
        str << ("=" * (4-rem))
      end
      return str
    end

    # Encodes base64 and base64url encoded strings.
    # @param str [String]
    # @return [String]
    def self.encode64(str)
      return Base64.urlsafe_encode64(str).sub(/=+$/,'')
    end

    # Decodes base64 and base64url encoded strings.
    # @param str [String]
    # @return [String]
    def self.decode64(str)
      str = str.gsub(/\s+/,'').tr('-_','+/').sub(/=+$/,'')
      return Base64.decode64(pad64(str))
    end

    # Decode the Compact Serialization of a thing.
    # @param str [String]
    # @return [Hash|String|Object]
    def self.compact_decode(str)
      return JSON.parse(decode64(str))
    end

    # Create a Compact Serialization of a thing.
    # @param thing [Hash|String|Object] anything, passed to JSON.generate.
    # @return [String]
    def self.compact_encode(thing)
      return encode64(JSON.generate(thing))
    end
  end
end
