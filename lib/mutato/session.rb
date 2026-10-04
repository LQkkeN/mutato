# frozen_string_literal: true

module Mutato
  class Session
    def initialize(mode, selection, console)
      @mode = mode
      @selection = selection
      @console = console
    end

    def call
      todo = chosen
      @console.say(*@selection.summary(todo))
      nothing if todo.empty?
      try(todo, Boot.new(@selection, @console).suite(todo))
    end

    private

    def chosen
      todo = @mode.todo(@selection)
      unknown = @selection.unknown(todo)
      @console.die("no such mutant: #{unknown.join(", ")}") if unknown.any?
      @selection.chosen(todo)
    end

    def nothing
      @console.die(
        "nothing to mutate under #{@selection.paths.join(" ")}",
        code: @selection.options.diff ? 0 : 3
      )
    end

    def try(todo, suite)
      started = Clock.now
      campaign = Campaign.new(suite, @console)
      outcomes = campaign.try(todo) { |partial| conclude(partial, campaign, started) }
      finish(conclude(outcomes, campaign, started))
    ensure
      suite.adapter.suite_done
    end

    def conclude(outcomes, campaign, started)
      flaky = campaign.experience.flaky
      Report.new(outcomes, @mode, @console).show(started, flaky)
      campaign.suite.output.write(outcomes, flaky)
      outcomes
    end

    def finish(outcomes)
      @mode.annotate(outcomes, @console, @selection.options.format)
      @mode.exit_code(outcomes)
    end
  end
end
