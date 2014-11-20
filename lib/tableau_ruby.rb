$:.unshift File.dirname(__FILE__)

require 'faraday_middleware'
require 'faraday_middleware/multi_json'

require 'tableau_ruby/project'
require 'tableau_ruby/session'
require 'tableau_ruby/site'
require 'tableau_ruby/user'
require 'tableau_ruby/version'
require 'tableau_ruby/workbook'