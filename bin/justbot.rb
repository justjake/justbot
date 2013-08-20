#!/usr/bin/env ruby
require "rubygems"
require "bundler/setup"
require "cinch"

require "pry" # top-end CLI like ipython

$LOAD_PATH << File.join(
    File.dirname(
        File.dirname(
            File.absolute_path(__FILE__))), 'lib')

# base library - required for plugins
require "justbot"
# plugins that are advised for all bots
# TODO decide if we should put these basic plugin includes in library root
require "justbot/plugins"                   # register, help, admin

# special stuff
require "justbot/models/twitter"

# conclude Justbot DB setup
Justbot::Database.connect(File.join(Justbot::CONFIG_ROOT, 'dev_db.sqlite'))

# Wrapper around a Cinch bot in another thread.
# Lets us stop, start, and re-create the bot.
class BotManager

  attr_accessor :bot
  attr_accessor :thread

  # @param config [Block] Cinch bot configuration block
  def initialize(&config)
    @config = config
    return create_bot
  end

  # create a new bot with our config
  def create_bot
    derp = @config
    @bot = Cinch::Bot.new do 
      configure(&derp)
    end
  end

  # Start the bot
  def start
    @thread = Thread.new { @bot.start }
  end

  # Stop the bot
  def stop
    @bot.stop
    @thread.exit
  end
end

# the bot is configured for localhost,
# expecting you to either be on your IRC server,
# or be providing some sort of port forwarding (using SSH mayhaps?)
# on your own
mngr = BotManager.new do |c|
  c.nick = "justbot^testing"
  c.user = 'justbot'
  c.server = "localhost"
  c.realname = "Only a Bot"

  # Add more channels here
  c.channels = ["#jitl", "##", "#satly"]

  # plugins.plugins contains functionality
  # c.plugins.plugins = [Justbot::IRC::TumblrGuard, JITL::IRC::Friendly, JITL::IRC::Admin]
  c.plugins.plugins = Justbot::Plugins::All

  # Bot always addressable by its nick, or accepts commands directly via PM
  c.plugins.prefix = Justbot::Prefix

  #@todo: set log level
end

binding.pry
# mngr.start.join
