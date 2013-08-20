require 'twitter'
require 'yaml'
module Justbot
  module Plugins
    # tweet from IRC. Deal with it.
    class TweetHappens
      include Cinch::Plugin
      include Justbot::Helpful

      # twitter auth tokens for the app as a whole
      TOKENS = YAML.load_file(File.join(Justbot::CONFIG_ROOT, 'twitter.yaml'))['oauth']

      self.plugin_name = "Tweet"
      self.help = "commands your personal twitter account. Requires authentication (auth <password>)"

      document "!tweet", "!tweet UPDATE_TEXT", "share an update with your followers. NO PREFIX"
      match /^!tweet (.+)/, method: :tweet, use_prefix: false

      # decrypt the twitter token when a user logs in
      def session_authenticated(session, password)
        token = session.user.twitter_token
        if not token.nil?
          session.storage[:twitter] = token.decrypt_with(password)
        end
      end

      # tweet something for the sending user
      # @param [Cinch::Message] m
      # @param [String] tweet the text to tweet
      def tweet(m, tweet)
        s = Justbot::Session.for(m)

        # user not logged in
        if s.nil?
          m.reply('You need to log in to do that.')
          return
        end

        # user has no twitter credentials
        if s.storage[:twitter].nil?
          m.reply("Your twitter account is not connected. Please try 'twitter link' to get started.")
          return
        end

        begin
          client = Twitter::Client.new(
              :consumer_key => TOKENS[:consumer_key],
              :consumer_secret => TOKENS[:consumer_secret],
              :oauth_token => s.storage[:twitter][:token],
              :oauth_token_secret => s.storage[:twitter][:secret]
          )
          client.update(tweet)
          reply_in_pm(m, ["successfully tweeted."])
        rescue Twitter::Error::Unauthorized
          reply_in_pm(m, ["Your OAuth token was not authorized to update your status"])
        end
      end

    end

    All << TweetHappens
  end
end
