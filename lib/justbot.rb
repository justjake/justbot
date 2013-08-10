# The JustBot IRC bot
# is a collection of Cinch irc bot plugins
# and a user/admin/auth stack based on DataMapper
module Justbot
  # config files directory
  CONFIG_ROOT = File.join(File.dirname(File.dirname(__FILE__)), 'config')

  # bot responds to '<Bot Name>: ', in channels, or commands at the start of the line, in PMs
  #
  # determines what the bot responds to.
  # IRC bot commands must be prefixed by whatever Regex this returns
  # @return [Regex] command prefix
  Prefix = lambda do |m|
    if m.channel?
      Regexp.new("^" + Regexp.escape(m.bot.nick + ": " ))
    else
      /^/
    end
  end

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
  module_function :reply_in_pm, :notify_private_reply

  # Cinch IRC bot plugins.
  # Each plugin is a little bottle of functionality, containing regex matchers
  # and functions, and a little bit of stack-side documentation as well.
  module Plugins
    # a list of all the availible plugins. Very helpful when setting up a bot.
    # @example create a bot with all the features!
    #   bot = Cinch::Bot.new do
    #     configure do |c|
    #       c.plugins.plugins = Justbot::Plugins::All
    #     end
    #   end
    #   bot.start
    All ||= []
  end
end

require 'justbot/helpful'
