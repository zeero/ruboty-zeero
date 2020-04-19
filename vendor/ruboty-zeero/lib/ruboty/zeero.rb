require 'net/http'
require 'uri'
require 'json'
require 'date'
require 'logger'
require 'yaml'
require 'rss'

require 'chrono'
require 'qiita'

module Ruboty
  module Zeero
    @logger = Logger.new($stdout)

    class << self
      attr_reader :logger
    end
  end
end

require "ruboty/zeero/version"
# require lib/ruboty/handler/*.rb
Dir[File.expand_path('../handler', __FILE__) << '/*.rb'].each do |file|
  require file
end

