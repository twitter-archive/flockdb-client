require 'spec_helper'

describe Flock::SimpleOperation do
  describe "#to_thrift" do
    it "should add state to QueryTerm" do
      qt = stub('fake query term').to_thrift
      mock(Flock::QueryTerm).new([1,1,3], state = ['state1']){qt}
      Flock::SimpleOperation.new(Flock::Client.new(Flock::MockService), [1,1,3]).state(state).to_thrift
    end
  end
end
