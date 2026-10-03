# frozen_string_literal: true

# Stands in for a booted RSpec with a suite of one test: `add(2, 3)` is 5 on
# the calc fixture. Whatever a mutant of `add` does to that decides its fate.
class OneTestSuite
  TEST = "./spec/calc_spec.rb[1:1]"
  CALC = FixtureRuns.path("lib/calc.rb")
  public_constant :TEST, :CALC

  # The suite as a session hands it on: this adapter, a baseline in which the
  # one test covers `add`, and an output directory of its own.
  def self.suite(adapter = new, out: Scratch.dir)
    line = "#{CALC}:10"
    baseline = Mutato::Baseline.new(
      line_map: { line => [TEST] },
      durations: { TEST => 0.01 },
      order: { TEST => 0 },
      hooks: 0.0,
      locations: { TEST => "./spec/calc_spec.rb" },
      boot_lines: Set.new,
      loaded_files: Set[CALC]
    )
    Mutato::Suite.new(adapter:, baseline:, options: Mutato::Options.parse([]), output: Mutato::Output.new(out))
  end

  # The calc fixture defined afresh, quietly: other specs install mutants into it.
  def self.load_calc
    verbose = $VERBOSE
    $VERBOSE = nil
    load CALC
  ensure
    $VERBOSE = verbose
  end

  # The mutant of `add` that subtracts.
  def self.minus
    Mutato::Generator.read(CALC).mutations.find { |mutation| mutation.description == "replace `+` with `-`" }
  end

  attr_reader :current

  # `passes` decides the test; by default it is the test itself.
  def initialize(passes: -> { Fixture::Calc.new.add(2, 3) == 5 })
    @passes = passes
    @current = nil
  end

  def run(ids)
    passed = @passes.call
    Mutato::RSpecAdapter::Result.new(
      status: passed ? 0 : 1,
      outside: nil,
      failing: (TEST unless passed),
      ran: ids
    )
  end

  def stop; end
end
