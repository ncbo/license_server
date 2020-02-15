require 'openssl'
require 'base64'

#private_key = File.read($PRIVATE_KEY_FILE)
#public_key  = File.read($PUBLIC_KEY_FILE)
#
#d = Date.today >> 12
#
#string = "#{SecureRandom.uuid};#{d}"
#encrypted_string = EncryptionUtil.encrypt(private_key, string)
#puts "************"
#puts encrypted_string
#puts "************"
#puts
#
#
#decrypted_string = EncryptionUtil.decrypt(public_key, encrypted_string)
#puts "************"
#puts decrypted_string
#puts "************"

module EncryptionUtil
  class << self
    # Returns a Base64 encoded string with encryption
    def encrypt(key, string)
      aes_encrypt = OpenSSL::Cipher.new('AES-256-CBC').encrypt
      aes_encrypt.key = aes_key = aes_encrypt.random_key
      crypt = aes_encrypt.update(string) << aes_encrypt.final
      encrypted_key = rsa_key(key).private_encrypt(aes_key)
      [Base64.encode64(encrypted_key), Base64.encode64(crypt)].join("|")
    end

    # Return the raw string after decryption & decoding
    def decrypt(key, string)
      encrypted_key, crypt = string.split("|").map{ |a| Base64.decode64(a) }
      aes_key = rsa_key(key).public_decrypt(encrypted_key)
      aes_decrypt = OpenSSL::Cipher.new('AES-256-CBC').decrypt
      aes_decrypt.key = aes_key
      aes_decrypt.update(crypt) << aes_decrypt.final
    end

    private

    def rsa_key(key)
      OpenSSL::PKey::RSA.new(key)
    end
  end
end