# frozen_string_literal: true

require "stringio"
require_relative "../spec_helper"

# The commands that end before a suite boots, run in this process.
RSpec.describe Mutato::CLI do
  let(:out) { StringIO.new }
  let(:err) { StringIO.new }

  let(:console) { Mutato::Console.new(out:, err:) }

  def call(*argv)
    described_class.call(argv, console:)
  end

  around { |example| FixtureRuns.within(&example) }

  # A mutant that lets a run get as far as booting must fail, not recurse.
  before { allow(Mutato::Boot).to receive(:new).and_raise("no suite boots in this spec") }

  it("lists the mutants and exits 0") { expect(call("list", "lib")).to eq(0) }

  it "lists each mutant with its id on stdout" do
    call("list", "lib")
    listing = "lib/calc.rb:10:9: [arithmetic] replace `+` with `-`  (Fixture::Calc#add)"
    expect(out.string).to match(/^\h{12}  #{Regexp.escape(listing)}$/)
  end

  it "lists only the sample asked for" do
    call("list", "lib", "--sample", "2")
    expect(out.string.lines.size).to eq(2)
  end

  it "sums the listing up on stderr" do
    call("list", "lib")
    expect(err.string).to start_with("#{out.string.lines.size} mutants over 3 files")
  end

  it "prints the usage for --help and exits 0" do
    expect([call("--help"), out.string]).to match([0, start_with("usage: mutato")])
  end

  it "prints the version for --version and exits 0" do
    expect([call("--version"), out.string]).to eq([0, "mutato #{Mutato::VERSION}\n"])
  end

  {
    "an unknown command" => [%w[bogus], "usage: mutato"],
    "no path" => [%w[list], "usage: mutato"],
    "a missing path" => [%w[list nowhere], "no such path: nowhere"],
    "an unknown option" => [%w[list lib --bogus], "invalid option: --bogus; mutato --help"],
    "a missing config" => [%w[list lib --config nowhere.rb], "no such config: nowhere.rb"],
    "an unknown mutant id" => [%w[run lib --only nope], "no such mutant: nope"]
  }.each do |situation, (argv, reason)|
    it "refuses #{situation} with exit 1 and why" do
      expect([call(*argv), err.string]).to match([1, include(reason)])
    end
  end

  it "exits 3 when there is nothing to mutate" do
    expect(call("run", "lib", "--limit", "0")).to eq(3)
  end

  it "leaves the arguments it was given alone" do
    argv = %w[list lib]
    described_class.call(argv, console:)
    expect(argv).to eq(%w[list lib])
  end

  it "flushes what it printed" do
    allow(console).to receive(:flush)
    call("--version")
    expect(console).to have_received(:flush)
  end

  it "loads the hooks file named" do
    allow(Mutato).to receive(:config).and_return(Mutato::Config.new)
    call("list", "lib", "--config", "skip.mutato.rb")
    expect(err.string).to include("skipped Fixture::Calc#clamp: demo")
  end

  { "run" => Mutato::Mode::Run, "control" => Mutato::Mode::Control }.each do |command, mode|
    it "hands #{command} to a session in its mode" do
      allow(Mutato::Session).to receive(:new).and_return(instance_double(Mutato::Session, call: 0))
      call(command, "lib")
      expect(Mutato::Session).to have_received(:new).with(mode, anything, console)
    end
  end
end
