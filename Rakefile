ROOT_DIR = File.expand_path(File.dirname(__FILE__))

require 'rubygems' rescue nil
require 'rake'
require 'spec/rake/spectask'

task :default => :spec

desc "Run all specs in spec directory."
Spec::Rake::SpecTask.new(:spec) do |t|
  t.spec_opts = ['--options', "\"#{ROOT_DIR}/spec/spec.opts\""]
  t.spec_files = FileList['spec/**/*_spec.rb']
end

# gemification with jeweler
begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = "flockdb"
    gemspec.summary = "Ruby Flock client"
    gemspec.description = "Get your flock on in Ruby."
    gemspec.email = "freels@twitter.com"
    gemspec.homepage = "http://github.com/twitter/flockdb-client"
    gemspec.authors = ["Matt Freels", "Rael Dornfest", "Nick Kallen"]
    gemspec.add_dependency 'thrift', '>= 0.5.0'
    gemspec.add_dependency 'thrift_client', '>= 0.6.0'

    # development
    gemspec.add_development_dependency 'rspec'
    gemspec.add_development_dependency 'rr'
  end
rescue LoadError
  puts "Jeweler not available. Install it with: gem install jeweler"
end

namespace :thrift do
  task :prereq do
    raise "You need thrift version 0.5.0" unless `thrift -version`['0.5.0']
  end

  desc "Download latest flockdb.thrift"
  task :download => :prereq do
    `mkdir thrift; curl https://github.com/twitter/flockdb/raw/master/src/main/thrift/Flockdb.thrift > thrift/flockdb.thrift`
  end
  
  desc "Build flockdb.thrift"
  task :build => :prereq do
    exec("thrift --gen rb -o lib/flock thrift/flockdb.thrift")
  end
end

