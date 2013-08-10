require "twitter"
require "yaml"         # reads ../twitter.yaml for settings
require "htmlentities" # decodes &amp; and friends

module Justbot
  module Plugins
    # checks Twitter for statuses from followed, and prints new ones into the channel
    class TwitterFeed
      include Cinch::Plugin
      include Justbot::Helpful

      self.plugin_name = "TwitterFeed"
      self.help = "Listens for Tweets from followed users, then shares them with IRC"

      # where to load the twitter settings from
      SETTINGS_PATH = File.join(Justbot::CONFIG_ROOT, 'twitter.yaml')

      # we're limited by Twitter to 150 requests per hour
      # @todo use the streaming API instead
      timer 30, method: :check_updates

      def initialize *args
        super

        config = load
        @channels = config["channels"]

        # twitter auth needs symbol keys
        @twitter  = Twitter::Client.new(config['oauth'])
        @tokens = config['oauth']
        @decoder = HTMLEntities.new

        # we print tweets since @last_id, prevents repeats, and is more accurate than time
        @last_id  = tweet_timeline.last.id
      end

      document "twitter follow",
          'twitter follow USERNAME',
          'follow USERNAME to recieve twitter updates from them in IRC'
      match /twitter (?:follow|watch) ([^ ]+)/, method: :add_watched_user

      document "twitter latest",
          'show the latest tweet from followed users'
      match /twitter (?:last|latest)/, method: :show_latest_tweet

      document "twitter following",
          "show all the users this bot watches on Twitter"
      match /twitter (?:followed|show|users|following)/, method: :show_followed

      document "twitter update", "twitter update STATUS",
          "update @justbotirc's status. Must be an admin."
      match /twitter (?:update|tweet) (.+)/, method: :post_update

      document "twitter recap", "twitter recap NUM",
          "show the last NUM statuses posted by users @justbotirc follows"
      match /twitter r(?:ecap) ([0-9]+)/, method: :recap

      document "twitter followall", "follow every user registered with the bot"
      match /twitter followall/, method: :session_follow_all

      # adds a user to the list that we want to see tweets for
      def add_watched_user(m, username)
        # remove @ from front of user string before we check users
        if username[0] == '@'
          username[0] = ''
        end
        begin
          @twitter.follow(username)
          m.reply("successfully followed @#{username}")
        rescue Twitter::Error::NotFound, T
          m.reply("Uh, '@#{username}' wasn't found on the twitters", true)
        rescue Twitter::Error::Unauthorized
          m.reply("Sorry bro but you're unworthy, as in 403 Unworthy.", true)
        rescue Exception => msg
          m.reply(msg.to_s)
        end
      end

      # show the latest tweet for all users
      def show_latest_tweet(m)
        recap(m, 1)
      end

      # show who we're following
      def show_followed(m)
        list_members = @twitter.users(@twitter.friend_ids.ids)
        if list_members.length > 2
          users = list_members[0..-2].map{|u| '@' + u.screen_name}.join(', ')
          users += ", and @#{list_members.last.screen_name}"
        else
          users = list_members.map{|u| '@' + u.screen_name}.join(' and ')
        end
        m.reply("I'm following %s." % [users], true)
      end

      # check followed users for updates,
      #   merge the updates into a single timeline,
      #   then send the timeline to all our channels
      def check_updates
        merged_tweets = tweet_timeline(@last_id)

        if merged_tweets.length > 0
          debug "we have #{merged_tweets.length} new tweets!"
          @last_id = merged_tweets.last.id
          tweet_channels(merged_tweets)
        end
      end

      # post a twitter status update ("tweet") as the application account
      # @param [Cinch::Message] m command request from authenticated admin
      # @param [String] text the body of the tweet
      def post_update(m, text)
        if_admin(m) {@twitter.update(text)}
      end

      # print the last N tweets
      # @param [Cinch::Message] m command request
      # @param [String, Integer] num number of recent tweets to show
      def recap(m, num)
        num = -1 - (num.to_i - 1)
        tweets = tweet_timeline[num..-1]
        puts tweets.map{|t| [t.user.screen_name, t.text]}.inspect
        tweets.each {|t| m.reply(format_tweet t)}
      end

      # the sender follows all registered users that xe isn't already following
      # @param [Cinch::Message] m message from an authenticated user
      def session_follow_all(m)
        s = Session(m)
        if s
          t = @tokens.dup
          t[:oauth_token] =        s.storage[:twitter][:token]
          t[:oauth_token_secret] = s.storage[:twitter][:secret]
          client = Twitter::Client.new(t)
          my_friends = client.friend_ids.collection
          # exclude self
          my_friends << s.user.twitter_id

          # all the user ids that you don't follow
          successes = []
          user_ids = Justbot::User.all(:fields => [:twitter_id], :twitter_id.not => my_friends).map{|u| u.twitter_id}
          user_ids.each do |id|
            rescue_exception do
              client.follow(id)
            end
          end
          m.reply("followed #{user_ids.length.to_s} users", true)
        else
          m.reply("You need a session to do that.", true)
        end
      end

      protected

      # format a tweet for output into a channel
      # @param  [Twitter::Status] tweet
      # @return [String] a pretty IRC string with colors and everything...!
      def format_tweet(tweet)
        "#{Format(:green, '[')}%s %s#{Format(:green, ']')} %s" % [Format(:bold, Format(:blue, '@' + tweet.user.screen_name)),
                           Format(:blue, tweet.user.name),
                           @decoder.decode(tweet.text)]
      end

      # returns a merged timeline of all the followed users' tweets
      # @param [Fixnum] after_id show only tweets after this id
      def tweet_timeline(after_id = 1)
        @twitter.home_timeline(since_id: after_id).reverse
      end

      # notify channels of tweets
      # @param [Array<Twitter::Status>] tweets the things we need to share with everyone
      def tweet_channels(tweets)
        @channels.each do |channel_name|
          channel = Channel(channel_name)
          tweets.each do |tweet|
            channel.msg(format_tweet(tweet))
          end
        end
      end

      # save current settings to twitter.yaml
      def save
        old_settings = load
        File.open(SETTINGS_PATH) do |settings|
          settings.puts YAML::dump(old_settings.merge({'channels' => @channels}))
          debug "saved settings"
        end
      end

      # load settings from twitter.yaml
      def load
        settings = YAML.load_file(SETTINGS_PATH)
        debug "loaded settings"
        settings
      end

    end

    All << TwitterFeed
  end
end