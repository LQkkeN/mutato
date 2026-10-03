# frozen_string_literal: true

require_relative "../../spec_helper"

RSpec.describe Mutato::Mode::Control do
  let(:passed) { Records.outcome(:missed) }
  let(:unexercised) { Records.outcome(:uncovered, examples: 0) }
  let(:failed) { Records.outcome(:caught) }

  it "exits 0 when every method passed and one was exercised" do
    expect(described_class.exit_code([passed, unexercised])).to eq(0)
  end

  it "exits 1 when a method failed" do
    expect(described_class.exit_code([passed, failed])).to eq(1)
  end

  it "exits 3 when no method was exercised" do
    expect(described_class.exit_code([unexercised])).to eq(3)
  end

  it "lists the failures" do
    expect(described_class.summary([failed])).to eq(
      ["control FAILED:", "  caught lib/a.rb:3:5: [arithmetic] replace `+` with `-`"]
    )
  end

  it "says when it proved nothing" do
    expect(described_class.summary([unexercised])).to eq(
      ["control proved nothing: no reinstalled method was exercised by a test"]
    )
  end

  it "counts the methods that passed" do
    expect(described_class.summary([passed, unexercised])).to eq(
      ["control OK: 1 of 2 reinstalled methods passed their tests"]
    )
  end
end
