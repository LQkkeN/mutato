require_relative "../lib/adder"

# A failing test in the middle: under --fail-fast the third would never run.
RSpec.describe Adder do
  before(:all) { Adder.new.add(1, 1) }

  it("adds") { expect(described_class.new.add(2, 3)).to eq(5) }
  it("fails before any mutation") { expect(1).to eq(2) }
  it("adds zero") { expect(described_class.new.add(0, 4)).to eq(4) }
end
