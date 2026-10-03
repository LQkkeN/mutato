# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe Mutato::Equivalence do
  let(:file) { File.expand_path("../fixtures/supers/supers.rb", __dir__) }
  let(:mutations) do
    Mutato::Generator.read(file).mutations.to_h do |mutation|
      [[mutation.subject.qualified, mutation.description], mutation]
    end
  end

  def equivalent?(owner, description)
    described_class.equivalent?(mutations.fetch(["Supers::#{owner}#initialize", description]))
  end

  before { require file }

  it "proves removing a `super()` that reaches BasicObject changes nothing" do
    expect(equivalent?("Empty", "delete statement `super()`")).to be(true)
  end

  it "proves the same of a bare `super` in a method without parameters" do
    expect(equivalent?("Bare", "delete statement `super`")).to be(true)
  end

  it "proves the same of a `super()` that reaches Struct's, which leaves the members nil" do
    expect(equivalent?("Paired", "delete statement `super()`")).to be(true)
  end

  it "runs a `super()` that reaches an initialize the struct defines" do
    expect(equivalent?("Renamed", "delete statement `super()`")).to be(false)
  end

  it "runs a bare `super` that passes parameters on" do
    expect(equivalent?("Passing", "delete statement `super`")).to be(false)
  end

  it "runs a `super()` that reaches an initialize of the parent" do
    expect(equivalent?("Child", "delete statement `super()`")).to be(false)
  end

  it "runs a `super()` in a module, which goes wherever the module is included" do
    expect(equivalent?("Mixed", "delete statement `super()`")).to be(false)
  end

  it "runs a `super()` in a class this process never loaded" do
    source = "class NeverLoaded\n  def initialize\n    super()\n    @ready = true\n  end\nend\n"
    mutation = Mutato::Generation.new("lib/never_loaded.rb", source).generator.mutations
      .find { |candidate| candidate.description == "delete statement `super()`" }
    expect(described_class.equivalent?(mutation)).to be(false)
  end

  it "runs the other mutants of the same method" do
    expect(equivalent?("Empty", "delete statement `@empty = true`")).to be(false)
  end
end
