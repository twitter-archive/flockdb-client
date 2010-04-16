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
    gemspec.homepage = "http://twitter.com"
    gemspec.authors = ["Matt Freels", "Rael Dornfest", "Nick Kallen"]
    gemspec.add_dependency 'thrift', '0.2.0'
    gemspec.add_dependency 'thrift_client', '0.4.1'

    # development
    gemspec.add_development_dependency 'rspec'
    gemspec.add_development_dependency 'rr'
  end
rescue LoadError
  puts "Jeweler not available. Install it with: gem install jeweler"
end
