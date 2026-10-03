# Does not parse: the brace is never closed.
RSpec.describe "broken" do
  it("passes") { expect(1).to eq(1)
end
