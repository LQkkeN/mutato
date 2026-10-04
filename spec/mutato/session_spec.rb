# frozen_string_literal: true

require "stringio"
require_relative "../spec_helper"

# Booting RSpec inside RSpec is out, so the suite is the one-test stand-in.
RSpec.describe Mutato::Session do
  subject(:session) do
    selection = Mutato::Selection.new(%w[lib], Mutato::Options.parse(flags))
    described_class.new(mode, selection, Mutato::Console.new(out: printed, err: printed))
  end

  include_context "with the signal handlers restored"

  let(:mode) { Mutato::Mode::Run }
  # `a - b` for `a + b` in Fixture::Calc#add, as `mutato list lib` names it there.
  let(:flags) { %w[--only 968c86db16b7] }
  let(:printed) { StringIO.new }
  let(:adapter) { OneTestSuite.new }
  let(:suite) { OneTestSuite.suite(adapter) }

  around { |example| FixtureRuns.within(&example) }

  before do
    OneTestSuite.load_calc
    allow(Mutato::Boot).to receive(:new).and_return(instance_double(Mutato::Boot, suite:))
  end

  it("exits 0 when the mutant is caught") { expect(session.call).to eq(0) }

  it "says what it is about to try" do
    session.call
    expect(printed.string).to start_with("1 mutants over 3 files")
  end

  it "reports the results" do
    session.call
    expect(printed.string).to include("results: caught 1")
  end

  it "lets the framework finish" do
    allow(adapter).to receive(:suite_done)
    session.call
    expect(adapter).to have_received(:suite_done)
  end

  it "writes the outcomes" do
    allow(suite.output).to receive(:write)
    session.call
    expect(suite.output).to have_received(:write).with([include(outcome: :caught)], Set.new)
  end

  context "with a survivor and a format" do
    let(:flags) { %w[--only 968c86db16b7 --format plain] }
    let(:adapter) { OneTestSuite.new(passes: -> { true }) }

    it("exits 2") { expect(session.call).to eq(2) }

    it "annotates it" do
      session.call
      expect(printed.string).to include("lib/calc.rb:10:9: survived: replace `+` with `-`")
    end
  end

  context "when interrupted" do
    before { allow(suite.output).to receive(:append) { trap("TERM", "DEFAULT").call } }

    it "reports what it has before it ends" do
      expect { session.call }
        .to raise_error(Mutato::Abort, "interrupted by TERM")
        .and(change(printed, :string).to(include("results:")))
    end
  end

  context "with a control" do
    let(:mode) { Mutato::Mode::Control }
    let(:flags) { %w[--only control-Fixture::Calc#add] }

    it("passes it") { expect(session.call).to eq(0) }
  end

  shared_examples "an early end" do |code, message|
    it "ends the run with exit #{code} and says why" do
      expect { session.call }
        .to raise_error(having_attributes(code:, message:))
    end
  end

  context "with an id that names no mutant" do
    let(:flags) { %w[--only nope] }

    it_behaves_like "an early end", 1, "no such mutant: nope"
  end

  context "with nothing to try" do
    let(:flags) { %w[--limit 0] }

    it_behaves_like "an early end", 3, "nothing to mutate under lib"
  end

  context "with a diff that touches nothing" do
    let(:flags) { ["--diff", File::NULL] }

    it_behaves_like "an early end", 0, "nothing to mutate under lib"
  end
end
