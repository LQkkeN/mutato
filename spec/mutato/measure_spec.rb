# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe Mutato::Measure do
  subject(:measure) do
    described_class.new(
      status: 1,
      line_map: { "lib/a.rb:3" => %w[t1 t2], "lib/a.rb:4" => %w[t2] },
      durations: { "t1" => 0.5, "t2" => 0.25 },
      failed: %w[t2],
      seen: Set["lib/a.rb"],
      hooks: 2.0
    )
  end

  let(:baseline) { measure.baseline(locations: {}, boot_lines: Set.new, loaded_files: Set.new) }

  it "sums itself up" do
    expect(measure.summary(2.5)).to eq("baseline: status 1, 2.50s, 2 covered lines, 2 tests")
  end

  it("knows when some test passed") { expect(measure).not_to be_all_failed }
  it("knows when every test failed") { expect(measure.with(failed: %w[t1 t2])).to be_all_failed }

  it "leaves the failed tests out of the line map" do
    expect(baseline.line_map).to eq("lib/a.rb:3" => %w[t1], "lib/a.rb:4" => [])
  end

  it "leaves out a test a group hook credited but that never ran" do
    credited = measure.with(line_map: { "lib/a.rb:3" => %w[t1 t3] })
    expect(credited.baseline(locations: {}, boot_lines: Set.new, loaded_files: Set.new).line_map)
      .to eq("lib/a.rb:3" => %w[t1])
  end

  it("orders the tests as they ran") { expect(baseline.order).to eq("t1" => 0, "t2" => 1) }
  it("passes on the time the hooks took") { expect(baseline.hooks).to eq(2.0) }
end
