require 'openssl'
require 'base64'
require 'rspec'

module Justbot
  # Cryptographic functions, such as password hashing and (de)crypting tokens
  module Crypto
    # structure to hold ciphertext with its iv
    class Crypted < Struct.new(:text, :iv)
      def to_s
        text
      end
    end

    # @!visibility private
    # some salt value or something
    SALT = 'a*(SD*(#jkdkba78&T&55@bBnd'

    # one-way password hashing that is used for auth verification
    # @param [String] s password string to one-way hash
    # @return [String] hashed password
    def self.digest(s)
      Base64.encode64(Digest::SHA512.digest(s[0] + s + SALT))
    end

    # returns a key suitable for AES encryption given a password
    # @param [String] password
    # @return [String] OpenSSL compliant encryption key
    def self.key(password)
      OpenSSL::PKCS5.pbkdf2_hmac_sha1(password, SALT, 3000, 256)
    end

    # encrypt data
    # @param [String] cleartext the data to encrypt
    # @param [String] password encryption passphrase. A key will be derived via #key
    def self.crypt(cleartext, password)
      cipher = OpenSSL::Cipher::AES256.new(:CBC)
      # tell the cipher obj that we intend to encrypt
      cipher.encrypt
      cipher.key = key(password)
      iv = cipher.random_iv
      Crypted.new(Base64.encode64(cipher.update(cleartext) + cipher.final),
                  Base64.encode64(iv))
    end

    # decrypt data
    # @param [String, Crypted] ciphertext Either a string of ciphertext, or a Crypted struct
    #   that includes the ciphertext along with the inititialization vector
    # @param [String] password encryption passphrase.
    # @param [String] iv the initialization vector used to encrypt ciphertext. Optional if you pass a Crypted struct
    # @return [String] decrypted data
    def self.decrypt(ciphertext, password, iv = nil)
      # unwrap ciphertext struct
      if ciphertext.is_a? Crypted
        iv = ciphertext.iv
        ciphertext = ciphertext.text
      end

      decipher = OpenSSL::Cipher::AES256.new(:CBC)
      decipher.decrypt
      decipher.key = key(password)
      decipher.iv = Base64.decode64(iv)

      decipher.update(Base64.decode64(ciphertext)) + decipher.final
    end
  end

  # tests !>?!?!?!?!?
  # well, yes, cryto is hard
  describe Crypto do
    it "encrypts data" do
      data = "Hello, I am a text string"
      password = 'some password'
      c = Crypto.crypt(data, password)
      (c.to_s == data).should be_false
    end

    it "encrypts then decrypts data given a password" do
      data = "Hello, I am a text string that will be encrypted."
      password = 'some password'
      c = Crypto.crypt(data, password)
      un_c = Crypto.decrypt(c, password)
      un_c.should eq(data)
    end

    it "hashes passwords" do
      password = 'some password'
      hash = Crypto.digest(password)
      (hash == password).should be_false
    end

    it "hashes passwords to the same output" do
      hash = Crypto.digest('some password')
      hash2 = Crypto.digest('some password')
      hash.should eq(hash2)
    end
  end
end
