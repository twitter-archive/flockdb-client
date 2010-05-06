require 'spec_helper'

describe Flock::QueryTerm do
  describe '#new' do
    it 'should take states' do
      qt = Flock::QueryTerm.new("query", state = ['state1', 'state2'])
      qt.state.should == state
    end

    it 'should default to Positive state' do
      qt = Flock::QueryTerm.new("query")
      qt.state.should == [Flock::Edges::EdgeState::Positive]
    end
  end

  describe "#to_thrift" do
    it "should add state to thrift object" do
      qt = Flock::QueryTerm.new([1,1,3], state = ['state1', 'state2'])
      qt.to_thrift.state_ids.should == state
    end
  end
end
