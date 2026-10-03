require_relative "spec_helper"

# Runs first and never looks at Tariff.
RSpec.describe Greeter do
  it("greets") { expect(described_class.new.hi).to eq("hi") }
end
