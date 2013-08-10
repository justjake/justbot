module Justbot
  module Plugins
    # Controls access to bot "administration" functions
    class Admin
      include Cinch::Plugin
      include Justbot::Helpful

      self.plugin_name =  "Administration"
      self.help =         "Bot administration"

      document('admin add',
                         'admin add NICK PASSWORD',
                         'add the user with nickname "NICK" to the admin list with auth password "PASSWORD"')
      document('admin remove', 'admin remove NICK', 'remove NICK from the admin list')
      document('admin list', 'admin list', 'show the admin list')
      document('channel join', 'channel join #CHANNEL', 'tell the bot to join CHANNEL')
      document('channel leave', 'channel leave #CHANNEL', 'tell the bot to leave CHANNEL')
      document 'channel say', 'channel say #CHANNEL PHRASES', 'makes the bot say PHRASES in a channel'
      document('ops plz', 'op[s][ please| me| plz]', 'request op from the bot.')
      document('tellall', 'tellall MESSAGE', 'the bot repeats MESSAGE on all the channels it is in.')

      match /admin add (.+)/,     method: :admin_add
      match /admin remove (.+)/,  method: :admin_remove
      match /admin (list|show)/,  method: :admin_list
      match /channel join (.+)/,  method: :channel_join
      match /channel leave (.+)/, method: :channel_leave
      match /ops? (please|me|plz)/,     method: :op_request
      match /tellall (.+)/,     method: :tell_all
      match /say ([^ ]+) (.+)/,  method: :puppet


      # Reply with a no permissions message
      def no_permission(m)
        m.reply("You don't have permission to do that, bro.", true)
      end

      # Admin management

      # Add a admin user with the given username and password
      # @param {Cinch::Message} m message object implicitly passed by Cinch
      # @param {String} username user name/nick to add. Must already be a registerd
      #   user
      # @example
      #   JustBot: admin add tyrus DERP
      def admin_add(m, username)
        s = Session(m)
        user = Justbot::User.first(:name => username)

        if s && s.user.is_admin?
          if user
            user.is_admin = true
            user.save
          else
            m.reply("User '%s' not found" % [Format(:bold, username)])
          end
        else
          no_permission(m)
        end
      end

      # Remove an admin
      # @param {Cinch::Message} m
      # @param {String} username user to remove from admin list
      # @example
      #   JustBot: admin remove anneliu
      def admin_remove(m, username)
        s = Session(m)
        user = Justbot::User.first(:name => username)

        if s && s.user.is_admin?
          if user
            user.is_admin = false
            user.save
          else
            m.reply("User '%s' not found" % [Format(:bold, username)])
          end
        else
          no_permission(m)
        end
      end

      # list all admins
      # @example
      #   JustBot: admin list
      def admin_list(m, command)
        admins = Justbot::User.all(:is_admin => true)
        admins.map{ |u| u.name }.join(', ')
        m.reply('The admins are: ' + admins, true)
      end


      # Channel management

      # join the given channel
      # @example
      #   JustBot: channel join #justjake
      def channel_join(m, channel)
        if_admin(m) { @bot.join(channel) }
      end

      # leave the given channel. Will part with a message of the requesting user
      # @example
      #   JustBot: channel leave #general
      def channel_leave(m, channel)
        if_admin(m) { @bot.part(channel, "#{m.user.nick} requested I leave") }
      end

      # Request that the bot op you
      # @example
      #   /join ##
      #   JustBot: ops plz
      def op_request(m, request)
        if_admin(m) { m.channel.op(m.user) }
      end

      # Send message to all channels the bot is in
      # @example:
      #   JustBot: tellall I'm shutting down for new features!
      #   In each channel:
      #     JustBot> I'm shutting down for new features!
      def tell_all(m, message)
        if_admin(m) do
          @bot.channels.each {|c| c.send(message) }
        end
      end

      def puppet(m, target, message)
        if_admin(m) do
          Target(target).send(message)
        end
      end

      private

      # run a block if the user is an admin
      def if_admin(m, &block)
        s = Session(m)
        if s && s.user.is_admin?
          yield
        else
          no_permission m
        end
      end
    end

    All << Admin
  end
end