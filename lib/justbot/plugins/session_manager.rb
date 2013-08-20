module Justbot
  module Plugins
    # auths users and decryptes encrypted user content.
    #
    # SessionManger runs the following methods on all plugins that have them when certain events occur
    #     <plugin>#session_authenticated([Justbot::Session] new_session, [String] user_password)
    #     <plugin>#session_will_end([Justbot::Session] ending_session)
    #
    #  this seems like a lot of complexity that isn't immediatly clear to the developer....
    #  but I haven't yet figured out a way to do this... correctly
    #
    # @see SessionManager#auth
    # @see SessionManager#session_terminate
    class SessionManager
      include Cinch::Plugin
      include Justbot::Helpful

      self.plugin_name = "Sessions"
      self.help = "authenticates users and manages sessions"

      document 'auth', 'auth PASSWORD', 'try to log in as your current nick using PASSWORD'
      match /auth (.+)/, method: :auth

      document 'session?', 'find out if you have a session right now, and what your status is'
      match /session\??/, method: :session_info

      document 'log out', 'terminate your session.'
      match /log ?out/, method: :session_terminate


      # @!group User Messages
      INVALID_USER_OR_PASSWORD = 'unknown user or invalid password'
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
      def auth(m, password)
        user = Justbot::Models::User.first(:name => m.user.nick)

        if user.nil? or not user.authenticates? password
          sleep 1 # prevent timing attacks?
          m.reply(INVALID_USER_OR_PASSWORD, true)
          return
        end

        s = Justbot::Session.new(user, m.user.mask)

        # start session
        start_session(s)

        # run the hooks that any plugins may have
        # this allows plugins to decrypt thier models with the user's password
        bot.plugins.each do |plugin|
          if plugin.respond_to? :session_authenticated
            plugin.session_authenticated(s, password)
          end
        end

        # tell the user as though they'd run the "session?" command
        session_info(m)
      end


      # get info about your current session
      def session_info(m)
        s = Justbot::Session.for(m)
        if s.nil?
          m.reply("You don't currently have a session.")
          return
        end

        reply_in_pm(m) do |r|
          r << "You have a session!"
          r << "  mask:      #{s.mask}"
          r << "  expires:   #{s.expiration}"
          r << "  is authed: #{s.authed?}"
        end
      end

      # destroys the sending user's session
      def session_terminate(m)
        s = Justbot::Session.for(m)

        if s.nil?
          m.reply(NO_SESSION, true)
          return
        end

        # run hooks on session termination
        bot.plugins.each do |plugin|
          if plugin.respond_to? :session_will_terminate
            plugin.session_will_terminate(s)
          end
        end

        s.end!
        m.reply('session terminated.')
      end

      private

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
