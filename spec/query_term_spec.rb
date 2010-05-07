require 'spec_helper'

describe Flock::QueryTerm do
  describe '#new' do
    it 'should extract first 3 items into the query' do
      qt = Flock::QueryTerm.new([1, 1, 2, :positive, :negative])
      qt.query.should == [1, 1, 2]
    end

    it 'should extract states' do
      qt = Flock::QueryTerm.new([1, 1, 2, :positive, :negative])
      qt.states.should == [:positive, :negative]
    end

    it 'should default state to positive' do
      qt = Flock::QueryTerm.new([1, 1, 2])
      qt.states.should == [:positive]
    end
  end

  describe "#to_thrift" do
    it "should add state to thrift object" do
      qt = Flock::QueryTerm.new([1, 1, 2, :positive, :negative])
      qt.to_thrift.state_ids.should == [Flock::Edges::EdgeState::Positive, Flock::Edges::EdgeState::Negative]
    end
  end
end
