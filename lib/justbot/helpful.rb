module Justbot
  # Justbot's plugin mixin. Exent your plugin classes with this
  # module. Provides a variety of utility methods to interact with IRC
  # users
  #
  # Use {Justbot::Helpful::ClassMethods#document} to build IRC-side help
  # messages for your users
  module Helpful

    # utility function to reply to a message in a PM
    # @param [Cinch::Message] m the message to reply to
    # @param [Array<String>] reply_lines an array of message lines to send to the user
    # @yield a block in which you can easily add reply lines
    # @yieldparam [Array<String>] reply_lines all the reply lines
    # @yieldreturn [Array<String>] final message array to send to the user
    def reply_in_pm(m, reply_lines = [], &block)
      if block_given?
        reply_lines = yield(reply_lines)
      end
      reply_lines.each { |l| m.user.msg(l) }
    end

    # utility function to notify users that the bot is replying via PM
    # if the user is not PMing the bot
    # @param [Cinch::Message] m message to reply to
    # @param [String] message_type "message_type continues via PM", default 'your interaction'
    def notify_private_reply(m, message_type = 'your interaction')
      if m.channel?
        m.reply(message_type + ' continues via PM', true)
      end
    end

    # @see Justbot::Session#for
    def Session(mask)
      Justbot::Session.for(mask)
    end

    # run a block if the user for a given message is an admin
    # Or send a reply telling the user they do not have authorization
    # to perform an action
    # @param [Chinch::Message] m message
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


      # (see Justbot::Models::Tag#initialize)
      def define_tag(tag_name)
        Justbot::Models::TagType.new(tag_name)
      end
    end

    private

    # add class methods
    def self.included(by)
      by.extend ClassMethods
    end
  end
end

