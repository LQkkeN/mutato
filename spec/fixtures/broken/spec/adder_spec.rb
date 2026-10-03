require_relative "../lib/adder"

RSpec.describe Adder do
  it("adds") { expect(described_class.new.add(2, 3)).to eq(5) }
end
