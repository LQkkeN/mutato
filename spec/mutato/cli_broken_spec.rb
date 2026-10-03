# frozen_string_literal: true

require_relative "../spec_helper"

# A suite with one spec file that does not parse, next to one that passes.
RSpec.describe Mutato::CLI, :subprocess do
  let(:run) { FixtureRuns.run_in("broken", "run", "lib") }

  it("stops") { expect(run.status.exitstatus).to eq(1) }
  it("says why") { expect(run.stderr).to include("spec files failed to load") }
end
