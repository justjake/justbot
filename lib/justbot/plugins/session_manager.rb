module Justbot
  module Plugins
    # auths users
    class SessionManager
      include Cinch::Plugin
      include Justbot::Helpful

      self.plugin_name = "Sessions"
      self.help = "authenticates users and manages sessions"

      document 'auth', 'auth PASSWORD', 'try to log in as your current nick using PASSWORD'
      match /auth (.+)/, method: :auth

      document 'authuser', 'authuser USERNAME PASSWORD', 'try to log in as USERNAME with password PASSWORD. Requires two-factor auth.'
      match /authu(?:ser)? ([^ ]+) (.+)/, method: :auth_user

      document 'authconfirm', 'authconfirm SECRET', 'complete two-factor auth, where SECRET is the message sent to you on Twitter by Justbot'
      match /authc(?:onfirm)? (.+)/, method: :auth_confirm

      document 'session?', 'find out if you have a session right now, and what your status is'
      match /session\??/, method: :session_info


      document 'log out', 'terminate your session.'
      match /log ?out/, method: :session_terminate


      # @!group User Messages
      INVALID_USER_OR_PASSWORD = 'unknown user or invalid password'
      INVALID_CONFIRM = 'confirmation incorrect or not required'
      NO_SESSION = 'you cannot do this because you have no session'
      SESSION_AUTHED = 'session already authenticated'
      SUCCESS = 'session created and authenticated!'
      # @!endgroup

      listen_to :nick
      # migrate sessions whenever nicks are changed
      def listen(m)
        oldmask = m.user.mask.to_s.split('!')
        oldmask[0] = m.user.last_nick
        oldmask = oldmask.join('!')
        s = Justbot::Session.for(oldmask)
        if s
          synchronize(:session) do
            s.mask = m.user.mask
          end
        else
          debug "no session found for mask '#{oldmask}'"
        end
      end

      # create a session for the messaging user and try to authenticate them with the password
      # @todo: DRY with this and {#auth_user}
      def auth(m, password)
        user = Justbot::User.first(:name => m.user.nick)

        if user.nil?
          sleep 1 # prevent timing attacks?
          m.reply(INVALID_USER_OR_PASSWORD, true)
          return
        end

        if user.authenticates? password
          s = Justbot::Session.new(user, m.user.mask)
          synchronize(:session) do
            # decrypt
            s.storage[:twitter] = user.twitter_token(password)
          end

          # start session
          start_session(s)
          session_info(m)
        else
          m.reply(INVALID_USER_OR_PASSWORD, true)
        end
      end

      # create a session for the messaging user, and log them in as the given username with password
      def auth_user(m, username, password)
        user = Justbot::User.first(:name => username)
        if user.nil?
          sleep 1
          m.reply(INVALID_USER_OR_PASSWORD, true)
          return
        end

        if user.authenticates? password
          secret = Justbot::Session.random_secret
          debug "Two-factor secret: #{secret}"
          s = Justbot::Session.new(user, m.user.mask, secret)
          synchronize(:session) do
            # decrypt
            s.storage[:twitter] = user.twitter_token(password)
          end

          # start session
          start_session(s)

          # inform them that they must two-factor
          twofactor_notice(m)

          # @todo: send two-factor message via Twitter
          session_info(m)

        else
          m.reply(INVALID_USER_OR_PASSWORD, true)
        end
      end

      # confirm a session that required two-factor authentication
      def auth_confirm(m, secret)
        s = Justbot::Session.for(m)
        if s.nil?
          m.reply(NO_SESSION, true)
          return
        end

        begin
          s.confirm_auth(secret)
          m.reply(SUCCESS, true)
        rescue Justbot::Session::SessionConfirmationError
          m.reply(INVALID_CONFIRM, true)
        end
      end

      # get info about your current session
      def session_info(m)
        s = Justbot::Session.for(m)
        if s.nil?
          m.reply("You don't currently have a session.")
          return
        else
          Justbot::reply_in_pm(m) do |r|
            r << "You have a session!"
            r << "  mask:      #{s.mask}"
            r << "  expires:   #{s.expiration}"
            r << "  is authed: #{s.authed?}"
          end
        end
      end

      # destroys the sending user's session
      def session_terminate(m)
        s = Session(m)
        if s
          s.end!
          m.reply('session terminated.')
        else
          m.reply(NO_SESSION, true)
        end
      end


      private

      # sends messages telling the user to look for thier two-factor secret
      def twofactor_notice(m)
        Justbot::reply_in_pm(m) do |r|
          r << "I have sent you a direct message on Twitter"
          r << "it contains a secret string."
          r << "to finish authenticating, type 'authconfirm SECRET'"
        end
      end

      # start a session and set up a timer to stop it, too
      def start_session(s)
        # callback to remove the session from play
        end_session_timer = Timer(
            Justbot::Session::DURATION,
            :stop_automatically => false,
            :shots => 1,
            :threaded => true
        ) do
          s.stop!
        end

        end_session_timer.start

        # start the session
        synchronize(:session) do
          s.storage[self] = {:timer => end_session_timer}
          s.start
        end
      end

    end

    All << SessionManager
  end
end