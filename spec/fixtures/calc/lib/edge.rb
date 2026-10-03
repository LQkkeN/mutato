module Fixture
  class Edge
    def codes
      [
        1, # one
        2, # two
      ]
    end

    def guarded(x)
      raise ArgumentError, <<~MSG if x.nil?
        x is required
      MSG

      "#{x} ok"
    end

    def cached
      return @cached if @cached

      @cached = codes.size
    end

    def shout(x)
      message = <<~MSG
        #{x}!
      MSG
      message.upcase
    end

    def log_result(x)
      logger.info(x)
    end

    def warn_if_slow(delay)
      return unless delay > 1

      logger.warn('slow')
    end

    tap do
      def fleeting
        :gone
      end
    end

    private

    def logger
      Logger
    end
  end
end
