# frozen_string_literal: true

module Mutato
  # Seconds from a clock the system never sets back.
  module Clock
    module_function

    def now
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end

    def since(started)
      now - started
    end

    # Seconds until the deadline, never negative; nil without one.
    def left(deadline)
      [deadline - now, 0].max if deadline
    end
  end
end
