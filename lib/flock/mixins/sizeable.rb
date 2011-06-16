module Flock
  module Mixins
    module Sizeable
      def any?(&block)
        block_given? ? map(&block).any? : size > 0
      end

      def empty?
        size == 0
      end
    end
  end
end
