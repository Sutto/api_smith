require "rubygems"
require "rake/gempackagetask"
require "rake/rdoctask"

task :default => :package do
  puts "Don't forget to write some tests!"
end

spec = eval(File.read("api_smith.gemspec"))

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.gem_spec = spec
end

desc 'Clear out RDoc and generated packages'
task :clean => [:clobber_package]
