require 'rubygems'
require 'spec'

spec_dir = File.dirname(__FILE__)
$: << File.expand_path("#{spec_dir}/../lib")

require 'flock'
require 'flock/mock_service'

Spec::Runner.configure do |config|
  config.mock_with :rr
end

def new_flock_client
  Flock.new(Flock::MockService.new)
end
