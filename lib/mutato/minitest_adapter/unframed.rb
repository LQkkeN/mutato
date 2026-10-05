# frozen_string_literal: true

module Mutato
  module MinitestAdapter
    # Failure locations point at the test: the project's filter never sees mutato's frames.
    Unframed = Data.define(:inner) do
      def filter(backtrace)
        inner.filter(backtrace&.grep_v(FRAMES))
      end
    end
    private_constant :Unframed
  end
end
