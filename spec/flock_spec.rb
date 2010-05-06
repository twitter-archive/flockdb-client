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
  end
end
