module Justbot
  module Plugins

    # register new users with just a password. This is core
    # functionality
    class RegisterUser
      include Cinch::Plugin
      include Justbot::Helpful

      self.plugin_name = 'Registration'
      self.help = "register yourself as a persistent user."

      document 'register', "register PASSWORD", 
        "Create your user account with PASSWORD as your password"
      match /register ([^ ]+)/, method: :register_password

      # Register the messaging user with the given password
      def register_password(m, password)
        # gaurd against users who already have sessions
        session = Justbot::Session.for(m)
        if Justbot::Session.for(m)
          m.reply("Cannot register user '#{m.user.nick}': you are already logged in as #{session.user.name}")
          return
        end

        # guard against nicknames that are already registered
        if Justbot::Models::User.count(:name => m.user.nick) > 0
          m.reply("Cannot register user '#{m.user.nick}': your nick is already taken")
          return 
        end

        # Create user with the given passwoird
        Justbot::Models::User.create(
            :name =>                    m.user.nick,
            :password =>                Crypto.digest(password),
        )

        m.reply("You were successfully registered with username '#{m.user.nick}'")
      end

    end

    All << RegisterUser
  end
end
