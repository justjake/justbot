module Justbot
  # mixin to help Cinch plugins document themselves in a convenient way.
  module Helpful

    # @see Justbot#reply_in_pm
    def reply_in_pm(m, reply_lines = [], &block)
      Justbot.reply_in_pm(m, reply_lines, &block)
    end

    # @see Justbot#notify_private_reply
    def notify_private_reply(m, message_type = 'your interaction')
      Justbot.notify_private_reply(m, message_type)
    end

    # @see Justbot::Session#for
    def Session(mask)
      Justbot::Session.for(mask)
    end

    # run a block if the user is an admin
    def if_admin(m, &block)
      s = Session(m)
      if s && s.user.is_admin?
        yield
      else
        m.reply("you need to be an admin to do that.")
      end
    end

    # additional class methods for plugins
    module ClassMethods
      # Helps plugins document themselves at runtime for IRC users
      class Command < Struct.new(:name, :signature, :description)
      end

      # document an IRC-side command
      # @param [String] name command name
      # @param [String] signature command signature in human readable format
      # @param [String] desc description of what command does and other instructions
      # @example defining a command
      #   document 'help',
      #            'help [PLUGIN] [COMMAND]',
      #            'show help information for the bot, for PLUGIN in bot, or for a COMMAND in PLUGIN'
      # @overload document(name, desc)
      #   document a simple command where the name and signature are the same
      #   @param [String] name name of the command
      #   @param [String] desc command description
      def document(name, signature, desc = nil)
        @help_commands ||= []
        if desc.nil?
          @help_commands << Command.new(name, name, signature)
        else
          @help_commands << Command.new(name, signature, desc)
        end
      end

      # A way for the Help plugin to access human-readable information about
      # available commands
      def commands
        @help_commands
      end
    end

    private

    # add class methods
    def self.included(by)
      by.extend ClassMethods
    end
  end
end

