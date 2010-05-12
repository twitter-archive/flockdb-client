require 'spec_helper'

describe Flock::QueryTerm do
  describe '#new' do
    it 'requires a query of length 4' do
      lambda { Flock::QueryTerm.new([1, 1, 1, 1, 1]) }.should raise_error(ArgumentError)
    end

    it 'has a source, graph, destination, and states' do
      qt = Flock::QueryTerm.new([1, 1, 2, [Flock::Edges::EdgeState::Positive, Flock::Edges::EdgeState::Negative]])
      qt.source.should == 1
      qt.graph.should == 1
      qt.destination.should == 2
      qt.states.should == [Flock::Edges::EdgeState::Positive, Flock::Edges::EdgeState::Negative]
    end
  end

  it "is forward if source is a single integer" do
    qt = Flock::QueryTerm.new([1, 1, 2, []])
    qt.should be_forward

    qt = Flock::QueryTerm.new([1, 1, nil, []])
    qt.should be_forward

    qt = Flock::QueryTerm.new([1, 1, [2, 3], []])
    qt.should be_forward
  end

  it "is not forward if source is not a single integer" do
    qt = Flock::QueryTerm.new([[1, 2], 1, 3, []])
    qt.should_not be_forward

    qt = Flock::QueryTerm.new([nil, 1, 3, []])
    qt.should_not be_forward
  end

  describe "#to_thrift" do
    before do
      @term = Flock::QueryTerm.new([1, 1, 2, [Flock::Edges::EdgeState::Positive, Flock::Edges::EdgeState::Negative]])
      @backward = Flock::QueryTerm.new([nil, 1, 2, [Flock::Edges::EdgeState::Positive, Flock::Edges::EdgeState::Negative]])
    end

    it "should set is_forward correctly" do
      @term.to_thrift.is_forward.should == true
      @term.source = nil
      @term.to_thrift.is_forward.should == false
    end

    it "should switch source and destination ids for a backwards term" do
      @term.to_thrift.source_id.should == @term.source
      @term.to_thrift.destination_ids.should == [@term.destination].pack('Q*')

      @term.source = nil
      @term.to_thrift.source_id.should == @term.destination
      @term.to_thrift.destination_ids.should == nil

      @term.source = [1, 2]
      @term.to_thrift.destination_ids.should == @term.source.pack('Q*')
    end

    it "should add state to thrift object" do
      @term.to_thrift.state_ids.should == [Flock::Edges::EdgeState::Positive, Flock::Edges::EdgeState::Negative]
    end
  end
end
