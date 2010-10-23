# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run the gemspec command
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{flockdb}
  s.version = "0.4.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Matt Freels", "Rael Dornfest", "Nick Kallen"]
  s.date = %q{2010-10-22}
  s.description = %q{Get your flock on in Ruby.}
  s.email = %q{freels@twitter.com}
  s.extra_rdoc_files = [
    "LICENSE",
     "README.md"
  ]
  s.files = [
    ".gitignore",
     "LICENSE",
     "README.md",
     "Rakefile",
     "VERSION",
     "flockdb.gemspec",
     "lib/flock.rb",
     "lib/flock/client.rb",
     "lib/flock/mixins/sizeable.rb",
     "lib/flock/mock_service.rb",
     "lib/flock/operation.rb",
     "lib/flock/operations/complex_operation.rb",
     "lib/flock/operations/execute_operation.rb",
     "lib/flock/operations/execute_operations.rb",
     "lib/flock/operations/query_term.rb",
     "lib/flock/operations/select_operation.rb",
     "lib/flock/operations/simple_operation.rb",
     "lib/flock/service.rb",
     "lib/flock/thrift/edges.rb",
     "lib/flock/thrift/edges_types.rb",
     "lib/flock/thrift/flock_constants.rb",
     "lib/flock/thrift/flock_types.rb",
     "lib/flock/thrift/shards.rb",
     "lib/flockdb.rb",
     "spec/execute_operations_spec.rb",
     "spec/flock_spec.rb",
     "spec/mock_service_spec.rb",
     "spec/query_term_spec.rb",
     "spec/simple_operation_spec.rb",
     "spec/spec.opts",
     "spec/spec_helper.rb"
  ]
  s.homepage = %q{http://github.com/twitter/flockdb-client}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{Ruby Flock client}
  s.test_files = [
    "spec/execute_operations_spec.rb",
     "spec/flock_spec.rb",
     "spec/mock_service_spec.rb",
     "spec/query_term_spec.rb",
     "spec/simple_operation_spec.rb",
     "spec/spec_helper.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<thrift>, [">= 0.2.0"])
      s.add_runtime_dependency(%q<thrift_client>, [">= 0.4.1"])
      s.add_development_dependency(%q<rspec>, [">= 0"])
      s.add_development_dependency(%q<rr>, [">= 0"])
    else
      s.add_dependency(%q<thrift>, [">= 0.2.0"])
      s.add_dependency(%q<thrift_client>, [">= 0.4.1"])
      s.add_dependency(%q<rspec>, [">= 0"])
      s.add_dependency(%q<rr>, [">= 0"])
    end
  else
    s.add_dependency(%q<thrift>, [">= 0.2.0"])
    s.add_dependency(%q<thrift_client>, [">= 0.4.1"])
    s.add_dependency(%q<rspec>, [">= 0"])
    s.add_dependency(%q<rr>, [">= 0"])
  end
end

