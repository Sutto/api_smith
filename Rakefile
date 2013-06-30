require 'rubygems'
require 'rake/rdoctask'
require 'rspec/core'
require 'rspec/core/rake_task'
require 'bundler/gem_tasks'


task :default => :spec

desc "Run all specs in spec directory (excluding plugin specs)"
RSpec::Core::RakeTask.new(:spec)
