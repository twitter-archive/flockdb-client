require 'spec_helper'

describe Flock::ExecuteOperations do
  describe "#negate" do
    it "should create a negate operation" do
      mock(Flock::ExecuteOperation).new(Flock::Edges::ExecuteOperationType::Negate, Flock::QueryTerm.new([1,1,3]), nil)
      operation = Flock::ExecuteOperations.new(Flock::Client.new(Flock::MockService), nil)
      operation.negate(1,1,3)
    end
  end
end
