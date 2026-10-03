# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe Mutato::Installer do
  let(:generator) { Mutato::Generator.read(FixtureRuns.path("lib/calc.rb")) }
  let(:subjects) { generator.subjects.to_h { |subject| [subject.name, subject] } }
  let(:add) { subjects.fetch(:add) }

  # Each method's one arithmetic mutant, `a - b` for `a + b`, as source.
  let(:arithmetic) do
    mutations = generator.mutations.select { |mutation| mutation.genre == :arithmetic }
    mutations.to_h { |mutation| [mutation.subject.name, mutation.mutated_source(generator.source)] }
  end

  before { OneTestSuite.load_calc }

  it "redefines a method in its lexical nesting" do
    described_class.install(add, arithmetic.fetch(:add))
    expect(Fixture::Calc.new.add(2, 3)).to eq(-1)
  end

  it "redefines it without a warning, with warnings on" do
    expect { described_class.install(add, arithmetic.fetch(:add)) }
      .not_to output.to_stderr
  end

  it "leaves warnings on" do
    described_class.install(add, add.node.slice)
    expect($VERBOSE).to be(true)
  end

  it "redefines it back again" do
    described_class.install(add, arithmetic.fetch(:add))
    described_class.install(add, add.node.slice)
    expect(Fixture::Calc.new.add(2, 3)).to eq(5)
  end

  it "redefines a method of a Struct a constant names" do
    described_class.install(subjects.fetch(:doubled), arithmetic.fetch(:doubled))
    expect(Fixture::Calc::Pair.new(4).doubled).to eq(2)
  end

  it "keeps a private method private" do
    described_class.install(subjects.fetch(:secret), subjects.fetch(:secret).node.slice)
    expect(Fixture::Calc.private_instance_methods(false)).to include(:secret)
  end

  it "tells the installed method from one the tests put back" do
    installed = described_class.install(add, arithmetic.fetch(:add))
    OneTestSuite.load_calc
    expect(described_class.current(add)).not_to eq(installed)
  end

  it "reports code that does not load as unviable" do
    expect { described_class.install(add, "def add(a, b) = a +") }
      .to raise_error(described_class::Unviable, /SyntaxError/)
  end
end
