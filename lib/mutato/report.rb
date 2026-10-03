# frozen_string_literal: true

module Mutato
  class Report
    def initialize(outcomes, mode, console)
      @outcomes = outcomes
      @mode = mode
      @console = console
    end

    def show(started, flaky)
      @console.say(
        "\nresults: #{counts}",
        format("%<wall>.0fs wall%<mean>s", wall: Clock.since(started), mean:)
      )
      @console.say("#{flaky.size} flaky tests fail with and without a mutation") if flaky.any?
      @console.say(*@mode.summary(@outcomes))
    end

    private

    def counts
      groups = @outcomes.group_by { |outcome| outcome.fetch(:outcome) }
      groups.map { |name, list| "#{name} #{list.size}" }
        .join(", ")
    end

    def mean
      seconds = @outcomes.map { |outcome| outcome.fetch(:seconds) }
        .select(&:positive?)
      return "" if seconds.empty?

      format(", mean %<seconds>.2fs per executed mutant", seconds: seconds.sum / seconds.size)
    end
  end
end
