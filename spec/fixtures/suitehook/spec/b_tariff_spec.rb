require_relative "spec_helper"

RSpec.describe Tariff do
  it("charges") { expect(described_class.fee).to eq(10) }
end
