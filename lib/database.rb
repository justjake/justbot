# require basic DataMapper
require 'dm-core'
require 'dm-migrations'
require 'dm-transactions'
module Justbot
  # path to the users sqlite database
  DATABASE_PATH = File.join(CONFIG_ROOT, 'database.sqlite')
end
DataMapper::Logger.new($stdout, :debug)
DataMapper.setup(:default, 'sqlite://' + Justbot::DATABASE_PATH)
