# frozen_string_literal: true

require "stringio"
require_relative "../../spec_helper"

RSpec.describe Mutato::Mode::Run do
  let(:caught) { Records.outcome(:caught) }
  let(:missed) { Records.outcome(:missed, flaky: ["./spec/a_spec.rb[1:2]"]) }

  it "exits 2 when a mutant survives" do
    expect(described_class.exit_code([caught, missed])).to eq(2)
  end

  it "exits 2 when a mutant is unjudged" do
    expect(described_class.exit_code([Records.outcome(:unjudged)])).to eq(2)
  end

  it("exits 0 when none survives") { expect(described_class.exit_code([caught])).to eq(0) }
  it("lists nothing when none survives") { expect(described_class.summary([caught])).to eq([]) }

  it "lists a survivor no flaky test touched as it is" do
    expect(described_class.summary([Records.outcome(:missed)])).to eq(
      ["\nMISSED:", "  a1b2c3d4e5f6  lib/a.rb:3:5: [arithmetic] replace `+` with `-`"]
    )
  end

  it "annotates the survivors in the format asked for" do
    out = StringIO.new
    described_class.annotate([missed], Mutato::Console.new(out:, err: StringIO.new), "plain")
    expect(out.string).to eq("lib/a.rb:3:5: survived: replace `+` with `-`\n")
  end

  it "lists the survivors, with the flaky tests left out" do
    survivor = "a1b2c3d4e5f6  lib/a.rb:3:5: [arithmetic] replace `+` with `-`"
    expect(described_class.summary([caught, missed])).to eq(
      ["\nMISSED:", "  #{survivor}  (1 flaky tests excluded)"]
    )
  end
end
