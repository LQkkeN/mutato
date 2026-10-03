# frozen_string_literal: true

module Mutato
  # Past the budget it stops the framework and raises; the parent's SIGKILL is the backstop.
  class Watchdog
    def initialize(adapter, budget)
      @adapter = adapter
      @budget = budget
      @expired = false
      @running = nil
    end

    # A timeout whatever the tests made of it, as RSpec rescues the exception like any other,
    # unless a test had failed before time ran out.
    def run(ids)
      timer = Thread.new { expire }
      judged(guarded(ids))
    ensure
      timer&.kill
    end

    private

    def judged(verdict)
      return verdict unless @expired

      failing = verdict[:failing]
      failing && failing != @running ? verdict : { outcome: :timeout, running: @running }
    end

    def guarded(ids)
      @adapter.run(ids).outcome
    rescue SoftTimeout
      { outcome: :timeout, running: @running }
    rescue SystemExit, SignalException => error
      exited(error)
    end

    def expire
      sleep @budget
      @running = @adapter.current
      @expired = true
      @adapter.stop
      Thread.main.raise(SoftTimeout)
    end

    # A mutant forced an exit path.
    def exited(error)
      puts "#{error.class}: #{error.message}"
      current = @adapter.current
      { outcome: :caught, failing: current, ran: [current].compact }
    end
  end
end
