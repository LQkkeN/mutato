# frozen_string_literal: true

require "stringio"
require_relative "../spec_helper"

RSpec.describe Mutato::Report do
  let(:err) { StringIO.new }
  let(:outcomes) do
    [
      Records.outcome(:caught, seconds: 1.0),
      Records.outcome(:caught, seconds: 3.0),
      Records.outcome(:uncovered, seconds: 0.0)
    ]
  end
  let(:lines) { err.string.lines(chomp: true) }

  before do
    allow(Mutato::Clock).to receive(:now).and_return(112.0)
    console = Mutato::Console.new(out: StringIO.new, err:)
    described_class.new(outcomes, Mutato::Mode::Run, console).show(100.0, flaky)
  end

  context "without flaky tests" do
    let(:flaky) { Set.new }

    it("counts the outcomes") { expect(lines).to include("results: caught 2, uncovered 1") }

    it "gives the wall time and the mean of the mutants that ran" do
      expect(lines).to include("12s wall, mean 2.00s per executed mutant")
    end

    it("says nothing of flaky tests") { expect(err.string).not_to include("flaky") }
  end

  context "when no mutant ran a test" do
    let(:outcomes) { [Records.outcome(:uncovered, seconds: 0.0)] }
    let(:flaky) { Set.new }

    it("gives the wall time alone") { expect(lines).to include("12s wall") }
  end

  context "with flaky tests" do
    let(:flaky) { Set["./spec/a_spec.rb[1:1]"] }

    it "counts them" do
      expect(lines).to include("1 flaky tests fail with and without a mutation")
    end
  end
end
