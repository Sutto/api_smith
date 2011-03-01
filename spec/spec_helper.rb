ENV["RAILS_ENV"] ||= 'test'

require 'pathname'
require 'bundler/setup'

Bundler.setup
Bundler.require :default, :test

require 'api_smith'
require 'rr'
require 'json'

Dir[Pathname(__FILE__).dirname.join("support/**/*.rb")].each { |f| require f }

RSpec.configure do |config|
  config.mock_with :rr
end