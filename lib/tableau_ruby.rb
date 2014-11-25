$:.unshift File.dirname(__FILE__)

require 'nokogiri'
require 'faraday'
require 'faraday_middleware'
require 'faraday_middleware/multi_json'

Dir[File.dirname(__FILE__) + '/tableau_ruby/*.rb'].each do |file|
  require file
end