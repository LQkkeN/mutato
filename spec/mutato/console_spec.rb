# frozen_string_literal: true

require "stringio"
require_relative "../spec_helper"

RSpec.describe Mutato::Console do
  subject(:console) { described_class.new(out:, err:) }

  let(:out) { StringIO.new }
  let(:err) { StringIO.new }

  it "says each line on stderr" do
    console.say("one", "two")
    expect(err.string).to eq("one\ntwo\n")
  end

  it "prints results on stdout" do
    console.out("result")
    expect(out.string).to eq("result\n")
  end

  context "with files for streams" do
    let(:path) { File.join(Scratch.dir, "out") }
    let(:file) { File.open(path, "w") }

    after { file.close }

    it "writes progress unbuffered" do
      described_class.new(out:, err: file)
      expect(file.sync).to be(true)
    end

    it "writes results out when flushed" do
      console = described_class.new(out: file, err:)
      console.out("result")
      console.flush
      expect(File.read(path)).to eq("result\n")
    end
  end

  it "ends the run with exit code 1 by default" do
    expect { console.die("gone") }
      .to raise_error(having_attributes(code: 1, message: "gone"))
  end

  it "ends the run with the code it is given" do
    expect { console.die("done", code: 3) }
      .to raise_error(having_attributes(code: 3))
  end
end
