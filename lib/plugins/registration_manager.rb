require 'yaml'            # for settings
require 'twitter_oauth'   # to create oauth token requests
require 'twitter'         # because fuck you thats why
module Justbot
  module Plugins
    # register new users and oauth their twitter creds
    # @todo allow users to register without OAuthing with twitter
    #    like if they want to use the bot for the other functions maybe
    class RegistrationManager
      include Cinch::Plugin
      include Justbot::Helpful

      # the registration states a user can be in
      module RegStatus
        LOGGED_IN = :currently_logged_in
        NICK_TAKEN = :nick_already_registered
        OAUTH_COMPLETE = :access_token_generated
        AWAITING_OAUTH = :requesting_access_token
        NEW_REGISTRATION = :new_registration
      end

      self.plugin_name = 'Registration'
      self.help = "create, authenticate, and verify users from a persistent users database"

      def initialize *args
        super

        @pending_registrations = {}
        @app_oauth = YAML.load_file(File.join(Justbot::CONFIG_ROOT, 'twitter.yaml'))['oauth']
        @app_token = @app_oauth.dup
        @app_oauth.delete(:oauth_token)
        @app_oauth.delete(:oauth_token_secret)
      end

      document 'register',
          "Start the registration process. You must have a Twitter username to register."
      match /register(?: (?:start|begin))?$/, method: :register_start

      document 'register oauth', 'register oauth PIN',
          "finish authorizing JustBot for your twitter account by inputting the PIN from twitter.com"
      match /register (?:oauth|pin) ([^ ]+)/, method: :register_oauth_pin

      document 'register complete', 'register complete PASSWORD',
        "Finish your registration, encrypting your credentials with PASSWORD."
      match /register complete (.+)/, method: :register_complete

      # begin the registration process
      def register_start(m)
        user_reg_status = registration_guard(m)
        if [RegStatus::NICK_TAKEN, RegStatus::LOGGED_IN, RegStatus::OAUTH_COMPLETE].include? user_reg_status
          # they've already recieved a message re: their status, so just abort
          return
        end

        if user_reg_status == RegStatus::AWAITING_OAUTH
          m.reply('Restarting your registration.', true)
        end

        # notify continuing via PM
        Justbot.notify_private_reply(m, 'registration')
        Justbot.reply_in_pm(m, ['To register you must authenticate via Twitter. Starting OAuth session...'])

        # do oauth stuff: generate request token
        client = TwitterOAuth::Client.new(@app_oauth)
        req = client.request_token(:oauth_callback => 'oob')
        @pending_registrations[m.user.mask] = {
            :client => client,
            :request_token => req
        }
        Justbot.reply_in_pm(m) { |r|
          r << 'go to %s to auth with twitter' % [Format(:bold, req.authorize_url)]
          r << "then oauth with this bot using " + Format(:bold, Format(:blue, 'register oauth'))
          r << "type 'register oauth YOUR_PIN_NUMBER'"
        }
      end

      # complete the oauth step by handing the app a oauth verifier in the form of a PIN
      def register_oauth_pin(m, pin)
        user_reg_status = registration_guard(m)
        if [RegStatus::NICK_TAKEN, RegStatus::LOGGED_IN].include? user_reg_status
          # they've already recieved a message re: their status, so just abort
          return
        end

        # registrations must start at #register_start
        if user_reg_status == RegStatus::NEW_REGISTRATION
          m.reply("Please begin the registration process by PMing 'register start'")
          return
        end

        # people who have oauthed already don't need to derp PINs again
        if user_reg_status == RegStatus::OAUTH_COMPLETE
          return
        end

        # do oauth stuff: generate authorization token
        c = @pending_registrations[m.user.mask][:client]
        r = @pending_registrations[m.user.mask][:request_token]
        begin
          @pending_registrations[m.user.mask][:access] = c.authorize(
              r.token,
              r.secret,
              :oauth_verifier => pin
          )
          help_complete_registration(m)
          # todo: handle all the crazy errors this throws
        rescue OAuth::Unauthorized
          m.reply("I was unable to authorize you. Please check your PIN and try again.")
        end
      end

      # complete the registration, encrypting and saving user data as a new User
      def register_complete(m, password)
        user_reg_status = registration_guard(m, false)
        if [RegStatus::NICK_TAKEN, RegStatus::LOGGED_IN].include? user_reg_status
          # they've already recieved a message re: their status, so just abort
          return
        end

        # registrations must start at #register_start
        if user_reg_status == RegStatus::NEW_REGISTRATION
          m.reply("Please begin the registration process by PMing 'register start'")
          return
        end

        # some people still need to enter pins
        if user_reg_status == RegStatus::AWAITING_OAUTH
          m.reply("You must oauth before you can complete registration.")
          m.reply("If you can't find your oauth URL, just start the registration process over with 'register begin'")
          return
        end

        reg = @pending_registrations.delete(m.user.mask)
        # sweet lets encrypt some stuff

        c_token =  Crypto.crypt(reg[:access].token, password)
        c_secret = Crypto.crypt(reg[:access].secret, password)

        # WOO NEW USER WITH OAUTH STUFF
        User.create(
            :name =>                    m.user.nick,
            :password =>                Crypto.digest(password),
            :twitter_id =>              reg[:client].info["id"],
            :crypted_twitter_token =>   c_token.text,
            :crypted_twitter_secret =>  c_secret.text,
            :iv_twitter_token =>        c_token.iv,
            :iv_twitter_secret =>       c_secret.iv
        )

        rescue_exception do
          # and.... follow them on twitter!
          c = Twitter::Client.new(@app_token)
          c.follow(reg[:client].info["id"])
        end

        m.reply('user %s created successfully!' % [Format(:bold, m.user.nick)])
      end

      private

      # determine the registration status of the IRC user
      # also sends messages relating to the status of the user
      # @param [Cinch::Message] m registration request message
      # @param [Boolean] send_comp_instructions if this user has oauth verified,
      #   should we inform them of registration completion steps?
      # @return [Symbol] state described in {Justbot::Plugins::AuthManager::RegStatus}
      def registration_guard(m, send_comp_instructions = true)
        # check to see if the user has a session...
        current_session = Justbot::Session.for(m)
        if current_session
          m.reply('Cannot register user: You are currently logged in as ', current_session.user.name)
          return RegStatus::LOGGED_IN
        end

        same_name_users = User.all(:name => m.user.nick)
        if same_name_users.length > 0
          m.reply('Cannot register user: your nick is already registered in the database. Authenticate instead.')
          return RegStatus::NICK_TAKEN
        end

        user_pending_registration = @pending_registrations[m.user.mask]
        if user_pending_registration
          if user_pending_registration[:access]
            # user already went through OAuth, but hasn't yet saved record to DB
            if send_comp_instructions
              help_complete_registration(m)
            end
            return RegStatus::OAUTH_COMPLETE
          else
            return RegStatus::AWAITING_OAUTH
          end
        end
        # I guess they have to be making a new registration, then
        RegStatus::NEW_REGISTRATION
      end

      # print a help message about completeing registration, after one provides an oauth verification
      def help_complete_registration(m)
        Justbot.reply_in_pm(m) {|r|
          r << 'OAuth token retrieved.'
          r << 'to complete your registration and securely encrypt your credentials, you need to supply a password using ' + Format(:bold, Format(:blue, 'register complete'))
          r << "type 'register complete YOUR_PASSWORD_HERE' to complete registration"
        }
      end


    end

    All << RegistrationManager
  end
end