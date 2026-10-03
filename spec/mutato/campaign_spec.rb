# frozen_string_literal: true

require "json"
require "stringio"
require_relative "../spec_helper"

RSpec.describe Mutato::Campaign do
  subject(:campaign) do
    described_class.new(OneTestSuite.suite(out: dir), Mutato::Console.new(out: StringIO.new, err:))
  end

  include_context "with the signal handlers restored"

  let(:dir) { Scratch.dir }
  let(:err) { StringIO.new }
  let(:reported) { [] }
  let!(:outcomes) do
    OneTestSuite.load_calc
    campaign.try([OneTestSuite.minus]) { |so_far| reported << so_far }
  end

  it("returns each mutant's outcome") { expect(outcomes.map { _1[:outcome] }).to eq([:caught]) }

  it "writes each outcome as it comes" do
    record = JSON.parse(File.read(File.join(dir, "outcomes.jsonl")))
    expect(record.fetch("outcome")).to eq("caught")
  end

  it("says how many it will try") { expect(err.string).to start_with("1 mutants to try\n") }

  it "shows its progress" do
    expect(err.string).to match(%r{^\s+1/1 caught\s+\d+\.\d\ds \h{12}  .*replace `\+` with `-`$})
  end

  %w[INT TERM].each do |signal|
    context "when interrupted by #{signal}" do
      let(:interrupt) { trap(signal, "DEFAULT") }

      it "ends the run" do
        expect { interrupt.call }
          .to raise_error(Mutato::Abort, "interrupted by #{signal}")
      end

      it "reports what it has first" do
        expect { interrupt.call }
          .to raise_error(Mutato::Abort)
          .and(change(reported, :size).from(0).to(1))
      end
    end
  end
end
