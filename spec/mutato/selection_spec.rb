# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe Mutato::Selection do
  subject(:selection) { described_class.new(paths, Mutato::Options.parse(flags.dup)) }

  let(:paths) { %w[lib] }
  let(:flags) { [] }
  let(:recorded) { FixtureRuns.path("mutants.txt") }
  let(:chosen) { selection.chosen(selection.mutations) }

  around { |example| FixtureRuns.within(&example) }

  # The fixture's every mutant, with the lines whose tests judge it, as
  # recorded. A change to what the generator makes of the fixture shows up
  # here; when it is meant, run with RECORD=1 to record it again.
  it "makes of the fixture what it did when recorded" do
    mutations = selection.mutations
    listing = [
      *mutations.map do |mutation|
        FixtureRuns.recorded_line(mutation)
      end,
      *selection.summary(mutations)
    ]
    File.write(recorded, listing.join("\n") << "\n") if ENV.fetch("RECORD", nil)
    expect(listing.join("\n")).to eq(File.read(recorded).chomp)
  end

  it "names every skipped method in the summary" do
    expect(selection.summary(selection.mutations))
      .to include("skipped Fixture::Calc#abstract: template stub  lib/calc.rb:31")
  end

  it "says nothing of files without methods or dropped mutants when there are none" do
    expect(selection.summary(selection.mutations).grep(/without methods|dropped/)).to be_empty
  end

  it "takes a directory's files in order" do
    expect(selection.files).to eq(%w[lib/calc.rb lib/edge.rb lib/more.rb])
  end

  it "takes the source roots as coverage names them" do
    expect(selection.prefixes).to eq([FixtureRuns.path("lib")])
  end

  context "with a path outside the current directory" do
    let(:paths) { %w[../outcomes/lib] }

    it "takes the path itself as the root" do
      expect(selection.prefixes).to eq([File.expand_path("../outcomes/lib")])
    end
  end

  context "with a file" do
    let(:paths) { %w[lib/calc.rb] }

    it("takes just that file") { expect(selection.files).to eq(%w[lib/calc.rb]) }

    it "takes its first directory as the root" do
      expect(selection.prefixes).to eq([FixtureRuns.path("lib")])
    end
  end

  context "with --limit" do
    let(:flags) { %w[--limit 3] }

    it "keeps the first mutants in file order" do
      expect(selection.mutations.map(&:line)).to eq([4, 4, 10])
    end
  end

  context "with --genre" do
    let(:flags) { %w[--genre statement,element] }

    it "keeps those genres only" do
      expect(selection.mutations.map(&:genre).uniq).to contain_exactly(:statement, :element)
    end
  end

  context "with --diff" do
    let(:flags) { %w[--diff clamp.diff] }

    it "keeps the mutants the diff touches" do
      expect(selection.mutations.map(&:line).uniq).to eq([14, 15])
    end
  end

  context "with --only" do
    let(:flags) { %w[--only 968c86db16b7] }

    it("picks mutants by id") { expect(chosen.map(&:id)).to eq(%w[968c86db16b7]) }
    it("knows every id") { expect(selection.unknown(selection.mutations)).to be_empty }
  end

  context "with --only naming an unknown id" do
    let(:flags) { %w[--only 968c86db16b7,nope] }

    it("names it") { expect(selection.unknown(selection.mutations)).to eq(%w[nope]) }
  end

  context "with --sample" do
    let(:flags) { %w[--sample 5] }

    it("draws that many") { expect(chosen.size).to eq(5) }

    it "draws the same every run" do
      again = described_class.new(paths, Mutato::Options.parse(flags.dup))
      expect(chosen.map(&:id)).to eq(again.chosen(again.mutations).map(&:id))
    end
  end

  context "with a sample larger than the list" do
    let(:flags) { %w[--sample 1000] }

    it("draws them all") { expect(chosen.size).to eq(selection.mutations.size) }
  end

  context "with files that have no methods and mutants that do not parse" do
    let(:paths) { %w[nowhere.rb] }
    let(:dropped) { Mutato::Generator.read("lib/calc.rb").mutations.first }

    before do
      generator = instance_double(
        Mutato::Generator,
        subjects: [],
        mutations: [],
        dropped: [dropped]
      )
      allow(Mutato::Generator).to receive(:read).and_call_original
      allow(Mutato::Generator).to receive(:read).with("nowhere.rb").and_return(generator)
    end

    it "says so" do
      expect(selection.summary([])).to eq(
        [
          "0 mutants over 1 files, 0 methods",
          "1 files without methods (code in blocks or at class level is not mutated)",
          "1 mutants dropped as unparsable, e.g. #{dropped.label}"
        ]
      )
    end
  end
end
