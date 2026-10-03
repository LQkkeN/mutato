# frozen_string_literal: true

require "stringio"
require_relative "../spec_helper"

RSpec.describe Mutato::Annotations do
  subject(:annotations) { described_class.new(Mutato::Console.new(out:, err: StringIO.new)) }

  let(:out) { StringIO.new }
  let(:outcomes) do
    [
      Records.outcome(:missed),
      Records.outcome(:timeout, line: 7),
      Records.outcome(:caught, line: 9)
    ]
  end

  context "with format github" do
    before { annotations.show(outcomes, "github") }

    it "warns of a survivor where it is" do
      warning = "::warning file=lib/a.rb,line=3,col=5,title=mutato::survived: replace `+` with `-`"
      expect(out.string).to include("#{warning}\n")
    end

    it "notes a timeout" do
      notice = "::notice file=lib/a.rb,line=7,col=5,title=mutato::timeout: replace `+` with `-`"
      expect(out.string).to include("#{notice}\n")
    end

    it("says nothing of a caught mutant") { expect(out.string.lines.size).to eq(2) }
  end

  context "with format plain" do
    before { annotations.show(outcomes, "plain") }

    it "prints a survivor as a path:line line" do
      expect(out.string).to eq("lib/a.rb:3:5: survived: replace `+` with `-`\n")
    end
  end

  context "without a format" do
    before { annotations.show(outcomes, nil) }

    it("prints nothing") { expect(out.string).to be_empty }
  end

  describe ".step_summary" do
    let(:path) { File.join(Scratch.dir, "summary.md") }

    before { allow(ENV).to receive(:fetch).with("GITHUB_STEP_SUMMARY", nil).and_return(path) }

    it "appends a table of the survivors" do
      described_class.step_summary([Records.outcome(:missed)])
      expect(File.read(path)).to eq(<<~MARKDOWN)
        ## mutato: 1 survivors

        | where | mutant |
        |---|---|
        | `lib/a.rb:3` | replace `+` with `-` |
      MARKDOWN
    end

    it "escapes the pipes of a description, so the row stays one row" do
      connector = Records.outcome(:missed, description: "replace `||` with `&&`")
      described_class.step_summary([connector])
      expect(File.read(path)).to include("| `lib/a.rb:3` | replace `\\|\\|` with `&&` |\n")
    end

    it "writes nothing without survivors" do
      described_class.step_summary([])
      expect(File).not_to exist(path)
    end
  end
end
