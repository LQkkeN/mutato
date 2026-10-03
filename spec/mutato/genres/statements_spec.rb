# frozen_string_literal: true

require_relative "../../spec_helper"

RSpec.describe Mutato::Genres::Statements do
  let(:descriptions) do
    lambda do |body|
      source = "class Walk\n  def call(node, count)\n#{body}\n  end\nend\n"
      Mutato::Generation.new("lib/walk.rb", source).generator.mutations.map(&:description)
    end
  end

  it "mutates a store a while loop reads on its next pass" do
    loop = "while node\n  node = count > 3\n  count += 1\nend\ncount"
    expect(descriptions.call(loop))
      .to include("delete statement `node = count > 3`", "replace `>` with `>=`")
  end

  it "mutates a store a block reads on its next call" do
    block = "3.times do\n  count += node\n  node = count - 1\n  count -= 1\nend\ncount"
    expect(descriptions.call(block)).to include("delete statement `node = count - 1`")
  end

  it "mutates a store an outer loop reads before the inner loop that writes it" do
    nested = "while node\n  2.times do\n    node = count - 1\n    count -= 1\n  end\nend\ncount"
    expect(descriptions.call(nested)).to include("delete statement `node = count - 1`")
  end

  it "mutates a store read before a later loop" do
    later = "seen = 2\nsum = seen + 1\n3.times { count += 1 }\nsum"
    expect(descriptions.call(later)).to include("delete statement `seen = 2`")
  end

  it "mutates a store whose value has an effect" do
    expect(descriptions.call("saved = node.save(count)\ncount"))
      .to include("delete statement `saved = node.save(count)`")
  end

  it "mutates a store that ends a branch: it is the branch's value" do
    branch = "x = if node\n  result = count + 1\nelse\n  0\nend\nx"
    expect(descriptions.call(branch)).to include("delete statement `result = count + 1`")
  end

  it "counts a compound assignment as a read" do
    expect(descriptions.call("n = count\nn += 1")).to include("delete statement `n = count`")
  end

  it "leaves a store nothing reads alone" do
    expect(descriptions.call("unused = count + 1\ncount"))
      .not_to include("delete statement `unused = count + 1`")
  end
end
