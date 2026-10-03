# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe Mutato::Covering do
  let(:mutations) { Mutato::Generator.read(OneTestSuite::CALC).mutations }
  let(:baseline) { OneTestSuite.suite.baseline }

  def covering(description)
    described_class.new(mutations.find { |mutation| mutation.description == description }, baseline)
  end

  it "finds the tests that run the mutant's statement" do
    expect(covering("replace `+` with `-`").ids).to eq([OneTestSuite::TEST])
  end

  it("finds none for a statement no test runs") { expect(covering("drop `1`").ids).to be_empty }

  it "calls a loaded file's untested line uncovered" do
    expect(covering("drop `1`").absence).to eq(:uncovered)
  end

  it "calls a file the suite never loaded unloaded" do
    baseline.loaded_files.clear
    expect(covering("drop `1`").absence).to eq(:unloaded)
  end

  {
    "a line booting ran" => [56, "drop `1`"],
    "a mutant in a block stored at load, by its statement" => [42, "delete statement `x * 2`"]
  }.each do |what, (line, description)|
    it "calls #{what} load-time" do
      baseline.boot_lines << "#{OneTestSuite::CALC}:#{line}"
      expect(covering(description).absence).to eq(:"load-time")
    end
  end

  context "when a test runs the lines of a block stored at load" do
    before { baseline.line_map["#{OneTestSuite::CALC}:43"] = [OneTestSuite::TEST] }

    it "finds no tests for a mutant inside, since none of them defined the block" do
      expect(covering("delete statement `x * 2`").ids).to be_empty
    end

    it "leaves the block's lines out of the mutants around it" do
      expect(covering("replace body of Fixture::Calc.define_double with nil").ids).to be_empty
    end

    it "finds the tests once one also runs the statement holding the block" do
      baseline.line_map["#{OneTestSuite::CALC}:42"] = [OneTestSuite::TEST]
      expect(covering("delete statement `x * 2`").ids).to eq([OneTestSuite::TEST])
    end
  end

  context "with a block inside a multi-line literal" do
    let(:more) { FixtureRuns.path("lib/more.rb") }
    let(:inside) do
      Mutato::Generator.read(more).mutations.find do |mutation|
        mutation.subject.name == :listed && mutation.description == "replace `*` with `/`"
      end
    end
    # Ruby's line event for the literal is on its first element, not on the bracket.
    let(:ran) do
      lines = File.readlines(more)
      %w[items: item.to_s].map do |text|
        "#{more}:#{lines.index { |line| line.include?(text) } + 1}"
      end
    end

    it "finds the tests through the literal's first element" do
      tested = baseline.with(line_map: ran.to_h { |line| [line, [OneTestSuite::TEST]] })
      expect(described_class.new(inside, tested).ids).to eq([OneTestSuite::TEST])
    end
  end

  it "calls an endless method uncovered, never load-time" do
    triple = Mutato::Generator.read(FixtureRuns.path("lib/more.rb")).mutations
      .find { |mutation| mutation.subject.name == :triple }
    file = triple.file
    booted = baseline.with(loaded_files: Set[file], boot_lines: Set["#{file}:#{triple.line}"])
    expect(described_class.new(triple, booted).absence).to eq(:uncovered)
  end
end
