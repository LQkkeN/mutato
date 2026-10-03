# frozen_string_literal: true

module Mutato
  # Outcomes are kept as they come, so an interrupt can still report them.
  class Campaign
    attr_reader :suite, :experience

    def initialize(suite, console)
      @suite = suite
      @console = console
      @experience = Experience.fresh
      @outcomes = []
    end

    def try(todo, &)
      watch(&)
      @console.say("#{todo.size} mutants to try")
      todo.each_with_index { |mutation, index| @outcomes << judge(mutation, index, todo) }
      @outcomes
    end

    private

    # Named, not anonymous: Ruby 3.3.0 rejects `&` forwarded from inside a block.
    def watch(&report)
      %w[INT TERM].each { |signal| trap(signal) { interrupted(signal, &report) } }
    end

    def interrupted(signal)
      yield(@outcomes)
      @console.die("interrupted by #{signal}")
    end

    def judge(mutation, index, todo)
      outcome = Trial.new(mutation, @suite, @experience).judge
      @suite.output.append(outcome)
      @console.say(progress("#{index + 1}/#{todo.size}", outcome, mutation))
      outcome
    end

    def progress(position, outcome, mutation)
      format(
        "%<position>8s %<outcome>-11s %<seconds>.2fs %<id>s  %<label>s",
        position:,
        outcome: outcome.fetch(:outcome),
        seconds: outcome.fetch(:seconds),
        id: mutation.id,
        label: mutation.label
      )
    end
  end
end
