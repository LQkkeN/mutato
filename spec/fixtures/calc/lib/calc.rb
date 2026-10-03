module Fixture
  class Calc
    def self.default_limit
      100
    end

    LIMIT = default_limit

    def add(a, b)
      a + b
    end

    def clamp(x, low, high)
      return low if x < low
      return high if x > high

      x
    end

    def describe(items)
      logger.debug('describing') if items.any?
      items.empty? ? 'none' : "#{items.size} items"
    end

    def ratio(a, b)
      a / b
    rescue ZeroDivisionError
      0
    end

    def abstract
      raise NotImplementedError
    end

    Pair = Struct.new(:a) do
      def doubled
        a * 2
      end
    end

    def self.define_double
      define_method(:double) do |x|
        x * 2
      end
    end

    define_double

    private

    def logger
      Logger
    end

    def secret
      [1, 2, 3]
    end
  end

  module Logger
    def self.debug(_message); end
  end
end
