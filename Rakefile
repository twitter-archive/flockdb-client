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

def run(cmd)
  system(cmd) or raise("Unable to run\n#{cmd}")
end

require 'bundler'
Bundler::GemHelper.install_tasks

namespace :thrift do
  task :prereq do
    raise "You need thrift version 0.5.0" unless `thrift -version`['0.5.0']
  end

  desc "Download latest flockdb.thrift"
  task :download => :prereq do
    run "mkdir -p thrift; curl https://github.com/twitter/flockdb/raw/master/src/main/thrift/Flockdb.thrift > thrift/flockdb.thrift"
  end
  
  desc "Build flockdb.thrift"
  task :build => :prereq do
    run "thrift --gen rb -o lib/flock thrift/flockdb.thrift"
  end
end

desc "Download & build latest flockdb thrift"
task :thrift => ['thrift:download', 'thrift:build']