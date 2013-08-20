module Justbot
  module Plugins
    # Prints plugin help information
    class Help
      include Cinch::Plugin
      include Justbot::Helpful

      # how much each line should be indented by
      SPACER = '  '

      self.plugin_name = 'Help'
      self.help = "Easily get help information about running IRC bot modules that use the Justbot help tools"

      document 'help',
               'help [PLUGIN] [COMMAND]',
               'show help information for the bot, for PLUGIN in bot, or for a COMMAND in PLUGIN'
      match /h[ea]lp$/,                   method: :help
      match /h[ea]lp ([^ ]+)$/,           method: :help_plugin
      match /h[ea]lp ([^ ]+) (.+)/,   method: :help_plugin_command

      # provide basic help, and list modules
      # @param [Cinch::Message] m help request message
      def help(m)
        notify_private_reply(m, "help messages")
        reply_in_pm(m) { |r|
          r << "Help for " + Format(:bold, Format(:blue, @bot.nick))
          r << "plugins: "
          r << bot_plugins.map{|p|  p.plugin_name }.join(', ')
          r << "documentation of the source code is online at " + Format(:blue, "http://jake.teton-landis.org/projects/justbot")
          r
        }
        help_plugin_command(m, self.class.plugin_name, 'help')
      end

      # print help information for the given plugin name
      def help_plugin(m, plugin_name)
        plugin = bot_plugin_for_name(plugin_name)
        if plugin.is_a? Class
          reply_in_pm(m) do |reply|
            reply << Format(:bold, Format(:blue, plugin.plugin_name))
            begin # Description
              reply << "Help:"
              reply << SPACER + plugin.help
            rescue NoMethodError
              no_help(m, plugin_name)
            end
            begin # Command listings
              if ! plugin.commands.nil?
                reply << 'Commands:'
                plugin.commands.each {|c| reply << SPACER + c.name}
              end
            rescue NoMethodError
              no_help(m, plugin_name, 'its commands')
            end
            reply
          end
        else
          not_found(m, plugin_name)
        end
      end

      # print help information for the given plugin command in plugin_name
      def help_plugin_command(m, plugin_name, command_name)
        plugin = bot_plugin_for_name(plugin_name)

        # fail fast - plugin class not fouind
        if not plugin.is_a? Class
          not_found(m, plugin_name)
          return
        end

        begin
          command = plugin_command_for_name(plugin, command_name)

          if command.nil?
            no_help(m, plugin_name, command_name)
            return
          end

          # print help
          reply_in_pm(m) do |reply|
            reply << "%s in %s" %
                [
                  Format(:bold, command.name),
                  plugin.plugin_name
                ].map{|n| Format(:blue, n)}
            reply << SPACER + command.signature
            reply << SPACER + command.description
          end
        rescue NoMethodError
          no_help(m, plugin_name)
        end
      end

      private

      # send a message saying a plugin or command was not found
      def not_found(m, plugin_name, command_name = nil)
        res = ""
        res = "command '#{command_name}' in " if command_name != nil
        res += "plugin '#{plugin_name}'"
        reply_in_pm(m, ["Not Found: #{res}"])
      end

      # send a message saying help is unavailable
      def no_help(m, plugin_name, command_name = nil)
        res = "plugin '#{plugin_name}' has no help data"
        res += " for #{command_name}" if command_name != nil
        reply_in_pm(m, [res])
      end

      # the running Cinch bot's' plugin classes, as configured
      # note that this is different from @bot.plugins because those are
      # plugin instances, and may be added dynamically
      def bot_plugins
        @bot.plugins.map{|p| p.class}
      end

      # select a plugin from the bot
      def bot_plugin_for_name(plugin_name)
        bot_plugins.select{|p| p.plugin_name.downcase.start_with? plugin_name.downcase}.first
      end

      # select a command object in a plugin
      def plugin_command_for_name(plugin, command_name)
        plugin.commands.select{ |c| c.name.downcase == command_name.downcase}.first
      end
    end

    All << Help
  end
end
