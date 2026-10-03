# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe Mutato::Baseline do
  subject(:baseline) do
    described_class.new(
      line_map: { "lib/a.rb:3" => %w[a b], "lib/a.rb:4" => %w[b c] },
      durations: { "a" => 1.0, "b" => 2.0, "c" => 4.0, "d" => 8.0 },
      order: { "a" => 0, "b" => 1, "c" => 2, "d" => 3 },
      hooks: 0.0,
      locations: {
        "a" => "./spec/other_spec.rb",
        "b" => "./spec/calc_helpers_spec.rb",
        "c" => "./test/test_helpers.rb",
        "d" => "./spec/helpers_spec.rb"
      },
      boot_lines: Set["lib/a.rb:1"],
      loaded_files: Set["lib/a.rb"]
    )
  end

  it("finds each test that covers the lines once") {
    expect(baseline.covering("lib/a.rb", [3, 4, 5])).to eq(%w[a b c])
  }

  it("gives the tests five times their time") { expect(baseline.budget(%w[a b], 10.0)).to eq(15.0) }
  it("gives them the minimum at least") { expect(baseline.budget(%w[a], 10.0)).to eq(10.0) }

  it "adds the time the hooks took" do
    expect(baseline.with(hooks: 11.0).budget(%w[a], 10.0)).to eq(21.0)
  end

  it("knows a file the suite loaded") { expect(baseline).to be_loaded("lib/a.rb") }
  it("knows a file it did not") { expect(baseline).not_to be_loaded("lib/b.rb") }
  it("knows a line booting ran") { expect(baseline).to be_booted("lib/a.rb", [2, 1]) }
  it("knows the lines it did not") { expect(baseline).not_to be_booted("lib/a.rb", [2, 3]) }

  def prioritized(file)
    baseline.prioritize(%w[d c b a], file)
  end

  it "runs tests named after the file first, then in baseline order" do
    expect(prioritized("lib/calc/helpers.rb")).to eq(%w[b c d a])
  end

  it "keeps the baseline order when no test is named after the file" do
    expect(prioritized("lib/other.rb")).to eq(%w[a b c d])
  end
end
