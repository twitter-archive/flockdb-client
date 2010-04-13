module Flock
  module Mixins
    module Sizeable
      def any?(&block)
        if !block_given?
          size > 0
        else
          map(&block).any?
        end
      end
      
      def empty?
        size == 0
      end
    end
  end
end
