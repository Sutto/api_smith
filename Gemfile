source "https://rubygems.org/"

gemspec

gem 'hashie', ENV.fetch('HASHIE_VERSION', '~> 1.0')
gem 'json'

group :development do
  gem 'rake'
  gem 'bluecloth'
  gem 'yard'
  gem 'awesome_print'
end

group :test do
  gem 'rspec'
  gem 'sham_rack'
  gem 'sinatra' # for sham_rack
end
