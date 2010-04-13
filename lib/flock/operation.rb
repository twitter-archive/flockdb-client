module Flock
  class Operation
    include Enumerable

    def initialize(count = 20, cursor = Flock::CursorStart, &block)
      @count, @next_cursor = count, cursor
      @get_results = block
      raise if @get_results.nil?
    end

    def paginate(count = 20, cursor = Flock::CursorStart)
      cursor ||= Flock::CursorStart
      Flock::Operation.new(count, cursor, &@get_results)
    end

    def current_page
      @current_page ||= begin
        current_page, @next_cursor, @prev_cursor = (memo[@next_cursor] ||= begin
          page = Flock::Page.new
          page.cursor = @next_cursor
          page.count = @count
          get_results(page)
        end)
        current_page.dup
      end
    end

    def memo
      @memo ||= {}
    end

    def set_current_page(cursor, results)
      current_page, @next_cursor, @prev_cursor = results
      @current_page = current_page.dup
      memo[cursor] = results
    end

    def take(count)
      result = []
      each_with_index do |item, i|
        break if i == count
        result << item
      end
      result
    end

    def get_results(page)
      @get_results.call(page)
    end

    def unapply
      [current_page, @next_cursor, @prev_cursor]
    end

    alias_method :to_ary, :to_a

    def first
      current_page.first
    end

    def each
      while next?
        yield(self.next)
      end
      self
    ensure
      reset
    end

    def reset
      @current_page = nil
      @prev_cursor = Flock::CursorEnd
      @next_cursor = Flock::CursorStart
    end

    def next?
      current_page.any? || next_page?
    end

    def prev?
      refuse.any? || prev_page?
    end

    def next
      raise unless next?
      item = current_page.shift
      item || next_page && self.next
    end

    def next_page
      raise unless next_page?

      @cursor = @next_cursor
      @current_page = nil
      current_page
    end

    def prev_page
      raise unless prev_page?

      @cursor = @prev_cursor
      @current_page = nil
      current_page
    end
    alias_method :previous_page, :prev_page

    def prev_page?
      @prev_cursor != Flock::CursorEnd
    end
    alias_method :previous_page?, :prev_page?

    def next_page?
      @next_cursor != Flock::CursorEnd
    end
  end
end