# -*- encoding: utf-8 -*-

require File.join(File.dirname(__FILE__), 'lib', 'flock', 'version')

Gem::Specification.new do |s|
  s.name = 'flockdb'
  s.version = Flock::VERSION
  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Matt Freels", "Rael Dornfest", "Nick Kallen"]
  s.summary = "Get your flock on in Ruby"
  s.description = "Get your flock on in Ruby."
  s.email = %q{freels@twitter.com}
  s.extra_rdoc_files = ['README.md', 'LICENSE']
  s.files = `git ls-files`.split("\n")
  s.homepage = %q{http://github.com/twitter/flock-client}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.7}
  s.test_files = `git ls-files`.split("\n").select{|f| f =~ /^spec/}
  s.rubyforge_project = 'flock-client'

  # dependencies
  s.add_dependency 'thrift', '>= 0.5.0'
  s.add_dependency 'thrift_client', '>= 0.6.0'
  s.add_development_dependency 'bundler', '~> 1.0.10'
  s.add_development_dependency 'rake', '= 13.0.1'
  s.add_development_dependency 'rspec', '~> 1.3.0'
  s.add_development_dependency 'diff-lcs'
  s.add_development_dependency 'rr'
end

