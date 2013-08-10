#!/usr/bin/env ruby
require "rubygems"
require "bundler/setup"
require "cinch"

$LOAD_PATH << File.join(
    File.dirname(
        File.dirname(
            File.absolute_path(__FILE__))), 'lib')

require "justbot"

# Persistent user stuff
require "justbot/crypto"
require "justbot/database"
require "justbot/user"
DataMapper.finalize

# plugins
require "justbot/plugins"

# the bot is configured for localhost,
# expecting you to either be on your IRC server,
# or be providing some sort of port forwarding (using SSH mayhaps?)
# on your own
bot = Cinch::Bot.new do
  configure do |c|
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
end

bot.start
