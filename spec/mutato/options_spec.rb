# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe Mutato::Options do
  subject(:options) { described_class.parse(argv) }

  let(:argv) do
    %w[lib --spec spec/unit --config hooks.rb --diff - --format plain --limit 3 --sample 7] +
      %w[--genre statement,value --only a1,b2 --out elsewhere --timeout-min 2.5 app]
  end

  it "leaves the paths in argv" do
    expect { options }
      .to change { argv }
      .to(%w[lib app])
  end

  it("reads the spec arguments") { expect(options.spec_args).to eq(%w[spec/unit]) }
  it("reads a file name") { expect(options.config).to eq("hooks.rb") }
  it("reads the diff source") { expect(options.diff).to eq("-") }
  it("reads the format") { expect(options.format).to eq("plain") }
  it("reads a count") { expect(options.limit).to eq(3) }
  it("reads the sample size") { expect(options.sample).to eq(7) }
  it("reads a list") { expect(options.only).to eq(%w[a1 b2]) }
  it("reads the output directory") { expect(options.out).to eq("elsewhere") }
  it("reads seconds") { expect(options.timeout_min).to eq(2.5) }
  it("keeps the genres named") { expect(options).to be_genre(:value) }
  it("drops the genres not named") { expect(options).not_to be_genre(:element) }

  context "with -h and --version" do
    let(:argv) { %w[-h --version] }

    it("asks for help") { expect(options.help).to be(true) }
    it("asks for the version") { expect(options.version).to be(true) }
  end

  context "with quotes in the spec arguments" do
    let(:argv) { ["--spec", "spec --pattern '**/*_test.rb'", "lib"] }

    it "reads them as a shell would" do
      expect(options.spec_args).to eq(%w[spec --pattern **/*_test.rb])
    end
  end

  {
    "an unknown genre, naming the genres" => [%w[--genre statements], "(genres: statement, "],
    "a negative count" => [%w[--limit -1], "--limit -1"],
    "a negative sample" => [%w[--sample -2], "--sample -2"]
  }.each do |what, (flags, message)|
    it "refuses #{what}" do
      expect { described_class.parse(flags + %w[lib]) }
        .to raise_error(OptionParser::InvalidArgument, a_string_including(message))
    end
  end

  context "without flags" do
    let(:argv) { %w[lib] }

    it("looks for specs in spec") { expect(options.spec_args).to eq(%w[spec]) }
    it("writes to mutato.out") { expect(options.out).to eq("mutato.out") }
    it("gives a mutant ten seconds at least") { expect(options.timeout_min).to eq(10.0) }
    it("has no config of its own") { expect(options.config).to be_nil }
    it("keeps every genre") { expect(options).to be_genre(:element) }
    it("asks for no help") { expect(options.help).to be_nil }
  end
end
