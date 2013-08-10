module Justbot
  module Models

    # stores encrypted twitter oauth tokens
    # owned by a {Justbot::Models::User}
    class TwitterToken
      belongs_to :user, :key => true

      # Twitter-user ID
      property :twitter_id,             Integer

      # encrypted properties
      property :crypted_twitter_token,  String, length: 120
      property :crypted_twitter_secret, String, length: 120

      # ecrypted property IVs
      property :iv_twitter_token,       String, length: 25
      property :iv_twitter_secret,      String, length: 25

      # decrypt the twitter oauth token and secret and return them
      def decrypt_with(password)
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
    end

    # add TwitterToken association from user
    class User
      has 1, :twitter_token, 'TwitterToken'
    end

  end
end
