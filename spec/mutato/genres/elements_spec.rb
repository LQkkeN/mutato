# frozen_string_literal: true

require_relative "../../spec_helper"

RSpec.describe Mutato::Genres::Elements do
  let(:drops) do
    lambda do |body|
      source = "class Lone\n  def call(x)\n#{body}\n  end\nend\n"
      mutations = Mutato::Generation.new("lib/lone.rb", source).generator.mutations
      mutations.filter_map { |mutation| mutation.description if mutation.genre == :element }
    end
  end

  it "leaves a lone hash element with a trailing comma alone" do
    expect(drops.call("{\n  a: x,\n}")).to be_empty
  end

  it "leaves a lone array element with a trailing comma alone" do
    expect(drops.call("[\n  x,\n]")).to be_empty
  end

  it "keeps the comma before a block argument when it drops the last keyword" do
    source = "class Lone\n  def call(x)\n    rows(head: x, foot: 1, &x)\n  end\nend\n"
    mutation = Mutato::Generation.new("lib/lone.rb", source).generator.mutations
      .find { |candidate| candidate.description == "drop `foot: 1`" }
    expect(mutation.apply(source)).to include("rows(head: x, &x)")
  end

  it "drops either of two elements" do
    expect(drops.call("[x, x + 1]")).to eq(["drop `x`", "drop `x + 1`"])
  end
end
