require "tmpdir"
require_relative "../lib/outcomes"
require_relative "../lib/gone"

RSpec.describe Outcomes do
  it("doubles") { expect(described_class.twice(2)).to eq(4) }
  it("counts") { expect(Outcomes::Loop.new.count(3)).to eq(3) }
  it("counts stubbornly") { expect(Outcomes::Stubborn.new.count(3)).to eq(3) }
  it("passes a value") { expect(Outcomes::Quits.new.check(5)).to eq(5) }
  it("survives no signal") { expect(Outcomes::Signals.new.check(5)).to eq(5) }
  it("adds") { expect(Outcomes::KEPT.new.x).to eq(2) }
  it("answers") { expect(Outcomes::Named.answer).to eq(42) }
  it("asks") { expect(Outcomes::Named.question).to eq(42) }
  it("is ready") { expect(Outcomes::Built.new).to be_ready }

  it "keeps the method it started with" do
    expect([Outcomes::Pinned.new.same?, Outcomes::Pinned.instance_method(:same?)])
      .to eq([true, Outcomes::Pinned::ORIGINAL])
  end

  it "reloads" do
    load File.expand_path("../lib/outcomes.rb", __dir__)
    expect(Outcomes::Reloaded.new.value).to eq(2)
  end

  # FIXTURE_TMP is one mutato run's scratch: the marker outlives the baseline.
  it "passes only the first time it runs" do
    value = Outcomes::Flaky.new.value
    marker = File.join(ENV.fetch("FIXTURE_TMP"), "flaky")
    first = !File.exist?(marker)
    File.write(marker, "")
    expect([value, first]).to eq([3, true])
  end
end
