# frozen_string_literal: true

require_relative "../spec_helper"

# Real forks, a stand-in for RSpec: see OneTestSuite.
RSpec.describe Mutato::Trial do
  let(:experience) { Mutato::Experience.fresh }

  def judge(mutation, adapter = OneTestSuite.new)
    described_class.new(mutation, OneTestSuite.suite(adapter), experience).judge
  end

  before { OneTestSuite.load_calc }

  it "catches a mutant the test notices" do
    expect(judge(OneTestSuite.minus)).to include(outcome: :caught, failing: OneTestSuite::TEST)
  end

  it "misses a method put back unchanged" do
    expect(judge(Mutato::Mutation.control(OneTestSuite.minus.subject))).to include(outcome: :missed)
  end

  it "gives the tests five times their time, ten seconds at least" do
    expect(judge(OneTestSuite.minus)).to include(budget: 10.0)
  end

  it("times the tests") { expect(judge(OneTestSuite.minus).fetch(:seconds)).to be_positive }

  it "leaves a mutant unjudged when its only test fails without it too" do
    expect(judge(OneTestSuite.minus, OneTestSuite.new(passes: -> { false })))
      .to include(outcome: :unjudged, flaky: [OneTestSuite::TEST])
  end

  it "remembers the flaky test for the next mutant" do
    judge(OneTestSuite.minus, OneTestSuite.new(passes: -> { false }))
    expect(experience.flaky).to eq(Set[OneTestSuite::TEST])
  end

  it "leaves out a test already known to be flaky" do
    experience.flaky << OneTestSuite::TEST
    expect(judge(OneTestSuite.minus)).to include(outcome: :unjudged)
  end

  it "judges a provably equivalent mutant without running it" do
    allow(Mutato::Equivalence).to receive(:equivalent?).and_return(true)
    allow(Mutato::Run).to receive(:new)
    expect(judge(OneTestSuite.minus)).to include(outcome: :equivalent)
  end

  it "says why no test judged a mutant no test runs" do
    secret = Mutato::Generator.read(OneTestSuite::CALC).mutations
      .find { |mutation| mutation.description == "drop `1`" }
    expect(judge(secret)).to include(outcome: :uncovered, examples: 0)
  end

  describe ".sequence_of" do
    {
      "the tests that ran" => [{ ran: %w[t1] }, %w[t1]],
      "them all when a child died before any ran" => [{ ran: [] }, %w[t1 t2]],
      "them all when a child said nothing" => [{}, %w[t1 t2]]
    }.each do |what, (result, sequence)|
      it("takes #{what}") { expect(described_class.sequence_of(result, %w[t1 t2])).to eq(sequence) }
    end
  end

  # Two tests, t1 then t2, and runs that answer from a script: the mutated
  # runs and the unmutated ones that confirm a kill, in the order they happen.
  context "with two tests" do
    let(:run) { instance_double(Mutato::Run) }
    let(:kill) { { outcome: :caught, failing: "t1", ran: %w[t1] } }
    let(:suite) do
      suite = OneTestSuite.suite
      baseline = suite.baseline.with(
        line_map: { "#{OneTestSuite::CALC}:10" => %w[t1 t2] },
        durations: { "t1" => 0.1, "t2" => 0.1 },
        locations: { "t1" => "./spec/a_spec.rb", "t2" => "./spec/a_spec.rb" }
      )
      suite.with(baseline:)
    end

    def scripted(*results)
      allow(Mutato::Run).to receive(:new).and_return(run)
      allow(run).to receive(:go).and_return(*results)
      described_class.new(OneTestSuite.minus, suite, experience).judge
    end

    it "blames the test that failed both ways, and judges by the rest" do
      outcome = scripted(
        { outcome: :caught, failing: "t1", ran: %w[t1 t2] },
        { outcome: :caught, failing: "t1", ran: %w[t1] },
        { outcome: :missed, ran: %w[t2] }
      )
      expect(outcome).to include(outcome: :missed, flaky: %w[t1])
    end

    it "blames the test that failed without the mutant, not the one that failed with it" do
      scripted(
        { outcome: :caught, failing: "t2", ran: %w[t1 t2] },
        { outcome: :caught, failing: "t1", ran: %w[t1] },
        { outcome: :caught, failing: "t2", ran: %w[t2] },
        { outcome: :missed, ran: %w[t2] }
      )
      expect(experience.flaky).to eq(Set["t1"])
    end

    it "blames the test an unmutated rerun hung on" do
      hung = { outcome: :timeout, running: "t1" }
      kill = { outcome: :caught, failing: "t2", ran: %w[t1 t2] }
      scripted(kill, hung, hung, { outcome: :missed })
      expect(experience.flaky).to eq(Set["t1"])
    end

    it "blames the last test when a child died without saying which" do
      died = { outcome: :caught, failing: nil }
      outcome = scripted(died, { outcome: :caught }, { outcome: :missed })
      expect(outcome).to include(outcome: :missed, flaky: %w[t2])
    end

    context "when the confirmation times out" do
      subject!(:outcome) { scripted(kill, { outcome: :timeout }, { outcome: :missed }) }

      it "gives it a second go, with twice the time" do
        expect(run).to have_received(:go).with(%w[t1], 20.0, log: end_with(".confirm")).once
      end

      it "counts the kill once the second go passes" do
        expect(outcome).to include(outcome: :caught)
      end
    end

    it "confirms a sequence once" do
      2.times { scripted(kill, { outcome: :missed }) }
      expect(Mutato::Run).to have_received(:new).with(suite, nil).once
    end
  end
end
