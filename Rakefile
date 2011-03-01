require 'rubygems'
require 'rake/gempackagetask'
require 'rake/rdoctask'
require 'rspec/core'
require 'rspec/core/rake_task'

spec = eval(File.read('api_smith.gemspec'))

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.gem_spec = spec
end

desc 'Cleans out the documentation and cache'
task :clobber_doc do
  rm_r '.yardoc' rescue nil
  rm_r 'doc' rescue nil
end


desc 'Clear out YARD docs and generated packages'
task :clean => [:clobber_package, :clobber_doc]

begin
  require 'yard'
  YARD::Rake::YardocTask.new :doc
rescue LoadError => e
  task :doc do
    warn 'YARD is not available, to generate documentation please install yard.'
  end
end


begin
  require 'ci/reporter/rake/rspec'
rescue LoadError
end

task :default => :spec

desc "Run all specs in spec directory (excluding plugin specs)"
RSpec::Core::RakeTask.new(:spec)