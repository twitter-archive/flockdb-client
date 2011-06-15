require 'spec/spec_helper'

describe Flock do
  attr_accessor :flock

  before do
    @flock = new_flock_client

    flock.add(1,1,2)
    flock.add(1,1,3)
    flock.add(2,1,1)
    flock.add(4,1,1)
  end

  describe 'add' do
    it 'works' do
      flock.contains(1,1,2).should == true
    end

    it 'works within nested transactions' do
      flock.transaction do
        flock.transaction do |f|
          f.add(1,1,5)
        end
      end
      flock.contains(1,1,5).should == true
    end
  end

  describe 'remove' do
    it 'works' do
      flock.remove(1,1,2)
      flock.contains(1,1,2).should == false
    end
  end

  describe 'negate' do
    it 'works' do
      flock.negate(1,1,2)
      flock.contains(1,1,2).should == false
    end
  end

  describe 'count' do
    it 'works' do
      flock.count(1,1,nil).should == 2
    end
  end

  describe 'archive' do
    describe 'forward' do
      describe 'one' do
        it 'works' do
          flock.archive(1,1,2)
          flock.contains(1,1,2).should == false
        end
      end

      describe 'many' do
        it 'works' do
          flock.archive(1,1,[2, 3])
          flock.contains(1,1,2).should == false
          flock.contains(1,1,3).should == false
        end
      end

      describe 'all' do
        it 'works' do
          flock.archive(1,1,nil)
          flock.contains(1,1,2).should == false
          flock.contains(1,1,3).should == false
        end
      end
    end

    describe 'backwards' do
      describe 'many' do
        it 'works' do
          flock.archive([2,4],1,1)
          flock.contains(2,1,1).should == false
          flock.contains(4,1,1).should == false
        end
      end

      describe 'all' do
        it 'works' do
          flock.archive(nil,1,1)
          flock.contains(2,1,1).should == false
          flock.contains(4,1,1).should == false
        end
      end
    end
  end

  describe 'unarchive' do
    describe 'forward' do
      before do
        flock.archive(1,1,nil)
      end

      describe 'one' do
        it 'works' do
          flock.unarchive(1,1,2)
          flock.contains(1,1,2).should == true
        end
      end

      describe 'many' do
        it 'works' do
          flock.unarchive(1,1,[2,3])
          flock.contains(1,1,2).should == true
          flock.contains(1,1,3).should == true
        end
      end

      describe 'all' do
        it 'works' do
          flock.unarchive(1,1,nil)
          flock.contains(1,1,2).should == true
          flock.contains(1,1,3).should == true
        end
      end
    end

    describe 'backwards' do
      before do
        flock.archive(nil,1,1)
      end

      describe 'many' do
        it 'works' do
          flock.unarchive([2,4],1,1)
          flock.contains(2,1,1).should == true
          flock.contains(4,1,1).should == true
        end
      end

      describe 'all' do
        it 'works' do
          flock.unarchive(nil,1,1)
          flock.contains(2,1,1).should == true
          flock.contains(4,1,1).should == true
        end
      end
    end
  end

  describe "positions" do
    it "works" do
      flock.add(4,5,6,:position => 7)
      flock.get(4,5,6).position.should == 7
    end

    it "behaves like the server, not moving position on double adds, but moving position on delete-add" do
      flock.add(4,5,6,:position => 7)
      flock.add(4,5,6,:position => 8)
      flock.get(4,5,6).position.should == 7
      flock.remove(4,5,6)
      flock.add(4,5,6,:position => 8)
      flock.get(4,5,6).position.should == 8
    end
  end

  describe 'select' do
    attr_accessor :query

    before do
      @query = flock.select(1,1,nil)
    end

    it "supports old style of select" do
      flock.select([1,1,nil]).to_a.sort.should == [2, 3]
    end

    it "supports selecting multiple nodes" do
      flock.select(1,1,[2,3]).to_a.sort.should == [2, 3]
    end

    it "turns nodes into ints if possible" do
      user = mock!.to_i { 1 }.subject
      flock.select(user, 1, nil).to_a.sort.should == [2, 3]
    end

    it "supports selecting states" do
      flock.remove(5,1,1)

      flock.select(5, 1, nil, 0).to_a.sort.should == []
      flock.select(5, 1, nil, :positive).to_a.sort.should == []
      flock.select([5, 1, nil, :positive]).to_a.sort.should == []
      flock.select(5, 1, nil, 1).to_a.sort.should == [1]
      flock.select(5, 1, nil, :removed).to_a.sort.should == [1]
      flock.select([5, 1, nil, :removed]).to_a.sort.should == [1]
      flock.select(5, 1, nil, 2).to_a.sort.should == []
      flock.select(5, 1, nil, :archived).to_a.sort.should == []
      flock.select([5, 1, nil, :archived]).to_a.sort.should == []
      flock.select(5, 1, nil, 0, 1, 2).to_a.sort.should == [1]
      flock.select(5, 1, nil, [0, 1, 2]).to_a.sort.should == [1]
      flock.select(5, 1, nil, [:positive, :removed, :archived]).to_a.sort.should == [1]
      flock.select([5, 1, nil, [:positive, :removed, :archived]]).to_a.sort.should == [1]
    end

    it 'supports rad graphs' do
      flock.select(1, :schmaph, nil).to_a.sort.should == [2, 3]
    end

    describe 'edges' do
      it 'works' do
        time = Time.now
        stub(Time).now { time }

        edge1 = Flock::Edges::Edge.new
        edge1.source_id = 1
        edge1.destination_id = 2
        edge1.position = Time.now.to_i
        edge1.updated_at = Time.now.to_i
        edge1.count = 1
        edge1.state_id = 0

        edge2 = Flock::Edges::Edge.new
        edge2.source_id = 1
        edge2.destination_id = 3
        edge2.position = Time.now.to_i
        edge2.updated_at = Time.now.to_i
        edge2.count = 1
        edge2.state_id = 0

        flock.select(1,1,nil).edges.to_a.should == [edge1, edge2]
      end
    end

    describe 'to_a' do
      it 'works' do
        flock.select(1,1,nil).to_a.sort.should == [2, 3]
      end
    end

    describe 'paginate' do
      it 'works' do
        page, next_cursor, prev_cursor = query.paginate(1).unapply

        page.should == [2]
        prev_cursor.should == Flock::CursorEnd
        next_cursor.should_not == Flock::CursorEnd

        page, next_cursor, prev_cursor = query.paginate(1, next_cursor).unapply

        page.should == [3]
        prev_cursor.should == Flock::CursorStart
        next_cursor.should == Flock::CursorEnd
      end

      describe 'next_page' do
        it 'works' do
          results = query.paginate(1)

          results.next_page?.should == true
          results.next_page.should == [2]

          results.next_page?.should == true
          results.next_page.should == [3]

          results.next_page?.should == false
        end
      end

      describe 'next' do
        it 'works' do
          results = query.paginate(2)

          results.next?.should == true
          results.next.should == 2

          results.next?.should == true
          results.next.should == 3

          results.next?.should == false
        end
      end
    end

    describe 'multi' do
      it 'works' do
        results = flock.multi do |m|
          m.select(1,1,nil)
          m.select(nil,1,1)
        end
        first, second = results
        first.to_a.should == [2, 3]
        second.to_a.should == [2, 4]
      end

      it 'works with empty multis' do
        results = flock.multi { |m| }
        results.to_a.should == []
      end

      describe 'edges' do
        it 'works' do
          time = Time.now
          stub(Time).now { time }

          prototype = Flock::Edges::Edge.new
          prototype.position = Time.now.to_i
          prototype.updated_at = Time.now.to_i
          prototype.count = 1
          prototype.state_id = 0

          results = flock.multi do |m|
            m.select(1,1,nil)
            m.select(nil,1,1)
          end.edges
          first, second = results

          a = prototype.dup
          a.source_id, a.destination_id = 1, 2

          b = prototype.dup
          b.source_id, b.destination_id = 1, 3

          first.to_a.should == [a, b]

          c = prototype.dup
          c.destination_id, c.source_id = 2, 1

          d = prototype.dup
          d.destination_id, d.source_id = 4, 1
          second.to_a.should == [c, d]
        end
      end
    end
  end
end
