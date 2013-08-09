#!/usr/bin/env ruby
# dev.rb
# development bot
require "rubygems"
require "bundler/setup"

require "cinch"

$LOAD_PATH << File.join(File.dirname(File.dirname(__FILE__)), 'lib')
require "base"

# Persistent user stuff
require "crypto"
require "database"
require "user"
DataMapper.finalize

# plugins
require "plugins"

# the bot is configured for localhost,
# expecting you to either be on your IRC server,
# or be providing some sort of port forwarding (using SSH mayhaps?)
# on your own
@bot = Cinch::Bot.new do
  configure do |c|
    c.nick = "testbot"
    c.user = 'justbot'
    c.server = "localhost"
    c.realname = "from future import brackets"

    # Add more channels here
    c.channels = ["#justjake"]

    # plugins.plugins contains functionality
    # c.plugins.plugins = [Justbot::IRC::TumblrGuard, JITL::IRC::Friendly, JITL::IRC::Admin]
    c.plugins.plugins = Justbot::Plugins::All

    # Bot always addressable by its nick, or accepts commands directly via PM
    c.plugins.prefix = Justbot::Prefix
  end
end

def start
  @bot.start
end

def stop(message = 'testbot shutting down')
  @bot.quit(message)
end

