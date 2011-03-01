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

desc "Cleans out the documentation and cache"
task :clobber_doc do
  rm_r ".yardoc" rescue nil
  rm_r "doc" rescue nil
end


desc 'Clear out YARD docs and generated packages'
task :clean => [:clobber_package, :clobber_doc]

begin
  require 'yard'
  YARD::Rake::YardocTask.new :doc
rescue LoadError => e
  task :doc do
    warn "YARD is not available, to generate documentation please install yard."
  end
end