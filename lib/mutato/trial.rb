# frozen_string_literal: true

module Mutato
  class Trial
    KILLS = %i[caught crashed].freeze
    private_constant :KILLS

    # A child that died before any example ran names no tests: the whole sequence stands.
    def self.sequence_of(result, remaining)
      ran = result.fetch(:ran, [])
      ran.empty? ? remaining : ran
    end

    def self.blame(result, sequence)
      return if result.fetch(:outcome) == :missed

      result[:failing] || result[:running] || sequence.last
    end

    def initialize(mutation, suite, experience)
      @mutation = mutation
      @suite = suite
      @experience = experience
    end

    def judge
      covering = Covering.new(@mutation, @suite.baseline)
      ids = covering.ids
      record = @mutation.record(ids)
      return record.merge(outcome: covering.absence) if ids.empty?

      record.merge(tried(ids))
    end

    private

    def tried(ids)
      return { outcome: :equivalent } if Equivalence.equivalent?(@mutation)

      timed(ids)
    end

    def timed(ids)
      budget = @suite.baseline.budget(ids, @suite.options.timeout_min)
      started = Clock.now
      result = verdict(ids - flaky, budget)
      result.merge(seconds: Clock.since(started), budget:, flaky: ids & flaky)
    end

    def flaky
      @experience.flaky.to_a
    end

    # A kill counts once the same tests pass unmutated; a test failing both ways is flaky.
    def verdict(remaining, budget)
      return { outcome: :unjudged } if remaining.empty?

      result = Run.new(@suite, @mutation).go(remaining, budget, log:)
      return result unless KILLS.include?(result.fetch(:outcome))

      confirm(result, remaining, budget)
    end

    def confirm(result, remaining, budget)
      sequence = Trial.sequence_of(result, remaining)
      culprit = culprit_of(sequence, budget)
      return result.merge(outcome: :caught) unless culprit

      @experience.flaky << culprit
      verdict(remaining - flaky, budget)
    end

    # The test the unmutated run failed or hung on; cached, as many kills share a sequence.
    def culprit_of(sequence, budget)
      culprits = @experience.culprits
      return culprits[sequence] if culprits.key?(sequence)

      result = unmutated(sequence, budget)
      culprits[sequence] = Trial.blame(result, sequence)
    end

    def unmutated(sequence, budget)
      result = Run.new(@suite, nil).go(sequence, budget, log: "#{log}.confirm")
      return result unless result.fetch(:outcome) == :timeout

      Run.new(@suite, nil).go(sequence, budget * 2, log: "#{log}.confirm")
    end

    def log
      @suite.output.log_path(@mutation.id)
    end
  end
end
