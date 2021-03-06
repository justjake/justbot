# The JustBot IRC bot
# is a collection of Cinch irc bot plugins
# and a user/admin/auth stack based on DataMapper
#
# check out the developer guide {file:DEVELOPERS.md here}.
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

end

# core library modules
require 'justbot/crypto'
require 'justbot/database'
require 'justbot/models/user'
require 'justbot/session'
require 'justbot/helpful'
