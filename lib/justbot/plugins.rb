module Justbot
  # Cinch IRC bot plugins.
  # Each plugin is a little bottle of functionality, containing regex matchers
  # and functions, and a little bit of stack-side documentation as well.
  module Plugins
    # a list of all the availible plugins. Very helpful when setting up a bot.
    #
    # Justbot loads only the most essentail plugins by default. Library users
    # may require extra plugins autonomously.
    # this way if Justbot is used as a library, esoteric plugins don't wear 
    # down our depenency graph.
    #
    # @example create a bot with all the features!
    #   bot = Cinch::Bot.new do
    #     configure do |c|
    #       c.plugins.plugins = Justbot::Plugins::All
    #     end
    #   end
    #   bot.start
    All = []
  end
end

require "justbot/plugins/admin"
require "justbot/plugins/help"
require "justbot/plugins/register_user"
require "justbot/plugins/session_manager"

# require "justbot/plugins/friendly"
# require "justbot/plugins/tumblrguard"
# require "justbot/plugins/tweet"
# require "justbot/plugins/twitter_watcher"
# require "justbot/plugins/steam"
