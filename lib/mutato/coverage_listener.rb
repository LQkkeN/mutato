# frozen_string_literal: true

require_relative "tally"

module Mutato
  class CoverageListener
    EVENTS = %i[example_group_started example_started example_finished].freeze
    public_constant :EVENTS

    attr_reader :tally

    def initialize(prefixes)
      @prefixes = prefixes
      @tally = Tally.fresh
      @hooks = GroupHooks.new
      @started = Clock.now
    end

    def example_group_started(_notification)
      @hooks.credit_suite(@tally.line_map) { read_hits }
      @hooks.expect_hooks
    end

    def example_started(notification)
      @started = Clock.now
      @hooks.credit(notification.example.example_group, @tally.line_map) { read_hits }
    end

    def example_finished(notification)
      example = notification.example
      id = example.id
      @tally.finish(id, Clock.since(@started), read_hits)
      @tally.failed << id if example.execution_result.status == :failed
    end

    private

    def read_hits
      @tally.read(@prefixes)
    end
  end
end
