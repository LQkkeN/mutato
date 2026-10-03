# frozen_string_literal: true

require "json"
require_relative "../spec_helper"

RSpec.describe Mutato::Output do
  subject(:output) { described_class.new(dir) }

  let(:dir) { Scratch.dir }
  let(:outcomes) { [Records.outcome(:caught, id: "c1"), Records.outcome(:missed, id: "m1")] }

  def read(name)
    File.read(File.join(dir, name))
  end

  it "puts a mutant's log in logs" do
    expect(output.log_path("m1")).to eq(File.join(dir, "logs", "m1.log"))
  end

  it "starts the outcomes of a new run afresh" do
    output.append(outcomes.first)
    described_class.new(dir).append(outcomes.last)
    expect(read("outcomes.jsonl").lines.size).to eq(1)
  end

  it "appends each outcome as a line of JSON" do
    outcomes.each { |outcome| output.append(outcome) }
    ids = read("outcomes.jsonl").lines.map { |line| JSON.parse(line).fetch("id") }
    expect(ids).to eq(%w[c1 m1])
  end

  context "when written" do
    before { output.write(outcomes, Set["./spec/a_spec.rb[1:1]"]) }

    it("keeps every outcome") { expect(JSON.parse(read("outcomes.json")).size).to eq(2) }

    it "lists each outcome's mutants" do
      expect(read("missed.txt")).to eq("m1  lib/a.rb:3:5: [arithmetic] replace `+` with `-`\n")
    end

    it "writes an empty list for an outcome no mutant had" do
      expect(read("timeout.txt")).to be_empty
    end

    it("lists the flaky tests") { expect(read("flaky.txt")).to eq("./spec/a_spec.rb[1:1]\n") }
  end

  describe ".cap" do
    let(:log) { File.join(dir, "big.log") }
    let(:megabyte) { "b" * 1_000_000 }

    it "keeps the last megabyte of a log that grew past it" do
      File.write(log, "#{"a" * 10}#{megabyte}")
      described_class.cap(log)
      expect(File.read(log)).to eq("mutato: log truncated to its last 1000000 bytes\n#{megabyte}")
    end

    it "leaves a short log alone" do
      File.write(log, "a")
      described_class.cap(log)
      expect(File.read(log)).to eq("a")
    end

    it "leaves a log of a megabyte alone" do
      File.write(log, megabyte)
      described_class.cap(log)
      expect(File.size(log)).to eq(1_000_000)
    end
  end
end
