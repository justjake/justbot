require "rubygems"
require "bundler/setup"

require "pry"

# Adds lib to $LOAD_PATH
$LOAD_PATH << File.join(File.dirname(__FILE__), 'lib')
require 'base'
require 'yaml'
TC = YAML.load_file(File.join(Justbot::CONFIG_ROOT, 'twitter.yaml'))

require 'crypto'
require 'database'
require 'user'
DataMapper.finalize

binding.pry
