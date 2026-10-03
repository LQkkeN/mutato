# frozen_string_literal: true

require_relative "../spec_helper"

# A project whose .rspec says --fail-fast, with a failing test before others.
RSpec.describe Mutato::CLI, :subprocess do
  let(:run) { FixtureRuns.run_in("failfast", "run", "lib") }

  it("runs the whole baseline") { expect(run.stderr).to include("3 tests") }
  it("judges the mutants and finds none missed") { expect(run.status.exitstatus).to eq(0) }
end
