require 'justbot/session'
module Justbot
  # Database-backed user structure that handles low-level authentication and sessions
  class User
    include DataMapper::Resource
    property :id,                     Serial
    property :name,                   String, required: true
    property :password,               String, required: true, length: 90

    # Roles
    property :is_admin,               Boolean, required: true, default: false
    property :is_owner,               Boolean, required: true, default: false

    # Twitter
    property :twitter_id,             Integer
    # encrypted properties
    property :crypted_twitter_token,  String, length: 120
    property :crypted_twitter_secret, String, length: 120
    # ecrypted property IVs
    property :iv_twitter_token,       String, length: 25
    property :iv_twitter_secret,      String, length: 25

    # test to see if the given password would authenticate the user
    def authenticates?(password)
      self.password == Crypto::digest(password)
    end

    # decrypt the twitter token and secret in this user and return them
    def twitter_token(password)
      token = Justbot::Crypto.decrypt(
          self.crypted_twitter_token,
          password,
          self.iv_twitter_token
      )
      secret = Justbot::Crypto.decrypt(
          self.crypted_twitter_secret,
          password,
          self.iv_twitter_secret
      )
      {:token => token, :secret => secret}
    end

    # is this user an admin?
    def is_admin?
      self.is_admin || self.is_owner
    end
  end
end

