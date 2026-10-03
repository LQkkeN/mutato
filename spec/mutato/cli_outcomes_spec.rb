# frozen_string_literal: true

require_relative "../spec_helper"

# Every outcome mutato can report, on a fixture with one method per outcome.
RSpec.describe Mutato::CLI, :subprocess do
  describe "run on the outcomes fixture" do
    let(:run) { FixtureRuns.run_in("outcomes", "run", "lib", "--timeout-min", "1") }
    let(:outcomes) { run.outcome_by_place }

    def outcome(place)
      outcomes.fetch(place)
    end

    it "installs a mutated class method" do
      expect(outcome("lib/outcomes.rb:6 replace `*` with `/`")).to eq("caught")
    end

    it "stops a loop with the soft timeout" do
      expect(outcome("lib/outcomes.rb:13 delete statement `i += 1`")).to eq("timeout")
    end

    it "kills a loop that swallows the soft timeout" do
      expect(outcome("lib/outcomes.rb:24 delete statement `i += 1`")).to eq("timeout")
    end

    it "installs a method its class defines by name" do
      expect(outcome("lib/outcomes.rb:65 replace `+` with `-`")).to eq("caught")
    end

    it "installs a method defined on a class beside it" do
      expect(outcome("lib/outcomes.rb:72 replace `*` with `/`")).to eq("caught")
    end

    it "catches a mutant that exits" do
      expect(outcome("lib/outcomes.rb:35 replace condition `x` with false")).to eq("caught")
    end

    it "catches a mutant that signals its own process" do
      expect(outcome("lib/outcomes.rb:43 replace condition `x.nil?` with true")).to eq("caught")
    end

    it "keeps the signalled child out of the report" do
      expect(run.stderr).not_to include("interrupted")
    end

    it "notices the tests reloading the method" do
      expect(outcome("lib/outcomes.rb:51 replace `+` with `-`")).to eq("overwritten")
    end

    it "leaves a mutant only a flaky test covers unjudged" do
      expect(outcome("lib/outcomes.rb:58 replace `+` with `-`")).to eq("unjudged")
    end

    it("lists the flaky test") { expect(run.file("flaky.txt")).to include("outcomes_spec.rb") }

    it "proves removing a `super()` that reaches nothing changes nothing" do
      expect(outcome("lib/outcomes.rb:90 delete statement `super()`")).to eq("equivalent")
    end

    it "runs the removal of a `super()` that reaches a parent's initialize" do
      expect(outcome("lib/outcomes.rb:102 delete statement `super()`")).to eq("caught")
    end

    it "cannot install a mutant of a class that is gone" do
      expect(outcome("lib/gone.rb:6 replace `+` with `-`")).to eq("unviable")
    end
  end

  describe "control on the outcomes fixture" do
    let(:run) { FixtureRuns.run_in("outcomes", "control", "lib", "--timeout-min", "1") }

    it("fails") { expect(run.status.exitstatus).to eq(1) }

    it "names the method its test pins" do
      expect(run.stderr).to match(/^  caught .*Pinned#same\? unchanged$/)
    end
  end
end
