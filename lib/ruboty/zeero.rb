module Ruboty
  module Zeero
    @logger = Logger.new($stdout)

    class << self
      attr_reader :logger
    end
  end
end

require 'ruboty/handler/cron'
require 'ruboty/handler/zeero'
require "ruboty/zeero/version"

