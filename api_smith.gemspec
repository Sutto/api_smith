# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)
require 'api_smith/version'

Gem::Specification.new do |s|
  s.name        = "api_smith"
  s.version     = APISmith::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Darcy Laycock"]
  s.email       = ["sutto@sutto.net"]
  s.homepage    = "http://github.com/filtersquad"
  s.summary     = "A simple layer on top of Faraday for building APIs"
  s.description = "APISmith provides tools to make working with structured HTTP-based apis even easier."
  s.required_rubygems_version = ">= 1.3.6"

  s.add_dependency 'hashie',   '~> 1.0'
  s.add_dependency 'faraday'
  s.add_dependency 'multi_json'

  s.add_development_dependency 'rr'
  s.add_development_dependency 'rspec', '~> 2.0'
  s.add_development_dependency 'fuubar'

  s.files        = Dir.glob("{lib}/**/*")
  s.require_path = 'lib'
end