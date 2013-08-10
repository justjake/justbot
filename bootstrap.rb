require "rubygems"
require "bundler/setup"

require "pry"
require 'twitter_oauth'

# Adds lib to $LOAD_PATH
$LOAD_PATH << File.join(File.dirname(__FILE__), 'lib')
require 'justbot'
require 'yaml'
TC = YAML.load_file(File.join(Justbot::CONFIG_ROOT, 'twitter.yaml'))

require 'justbot/crypto'
require 'justbot/database'
require 'justbot/user'
DataMapper.finalize

binding.pry
