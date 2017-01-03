require "ruboty/zeero/version"

module Ruboty
  module Zeero
    @@logger = Logger.new($stdout)
  end
end

require 'ruboty/handler/zeero'
require 'ruboty/handler/cron'
