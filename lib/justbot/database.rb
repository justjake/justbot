# require basic DataMapper
require 'dm-core'
require 'dm-migrations'
require 'dm-transactions'
require 'dm-aggregates'


module Justbot
  # manage this bot's connection to the databse
  module Database

    # path to the users sqlite database
    DefaultPath = File.join(Justbot::CONFIG_ROOT, 'database.sqlite')

    def self.connect(path = Justbot::Database::DefaultPath)
      DataMapper.setup(:default, 'sqlite://' + path)
      DataMapper.finalize
    end

    # recieve debug messages for each query
    def self.enable_debug
      DataMapper::Logger.new($stdout, :debug)
    end

  end
end
