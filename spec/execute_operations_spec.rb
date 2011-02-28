require 'spec_helper'

describe Flock::ExecuteOperations do
  describe "#negate" do
    it "should create a negate opperation" do
      mock(Flock::ExecuteOperation).new(Flock::Edges::ExecuteOperationType::Negate, [1,1,3], nil)
      operation = Flock::ExecuteOperations.new(Flock::Client.new(Flock::MockService), nil)
      operation.negate(1,1,3)
    end
  end

  describe "adding with timestamp" do
    it "should pass through" do
      service = Flock::MockService
      client = Flock::Client.new(service)
      now = Time.now.to_i
      thing = Flock::ExecuteOperations.new(service, Flock::Priority::High, now)
      mock(Flock::ExecuteOperations).new(service, Flock::Priority::High, now) { thing }
      client.add(1, 1, 3, Flock::Priority::High, :execute_at => now)
    end
  end

  describe "adding with position" do
    it "should pass through" do
      service = Flock::MockService
      client = Flock::Client.new(service)
      now = Time.now.to_i
      thing = Flock::ExecuteOperation.new(1, [1, 1, 3], 12345)
      mock(Flock::ExecuteOperation).new(1, [1, 1, 3], 12345) { thing}
      client.add(1, 1, 3, Flock::Priority::High, :position => 12345)
    end
  end

end
