# frozen_string_literal: true

require "coverage"
require_relative "coverage_listener/tally"

module Mutato
  # Each read clears the counters, so one read per example gives exactly its lines.
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
      @tally.finish(notification.example, Clock.since(@started), read_hits)
    end

    private

    def read_hits
      Coverage.result(stop: false, clear: true).flat_map do |path, data|
        next [] unless path.start_with?(*@prefixes)

        @tally.seen << path
        Hits.keys(path, data)
      end
    end
  end
end
