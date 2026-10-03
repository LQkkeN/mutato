# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe Mutato::Diff do
  subject(:diff) { described_class.new(text) }

  let(:text) do
    <<~DIFF
      --- a/lib/a.rb
      +++ b/lib/a.rb
      @@ -3,4 +3,5 @@
       context
      -removed
      +added one
      +added two
       context
      --- a/lib/b.rb
      +++ b/lib/b.rb
      @@ -10 +10 @@
      -old
      +new
    DIFF
  end

  it("counts an added line") { expect(diff).to be_touches("lib/a.rb", 4..4) }
  it("counts the next added line") { expect(diff).to be_touches("lib/a.rb", 5..5) }
  it("skips the context before") { expect(diff).not_to be_touches("lib/a.rb", 3..3) }
  it("skips the context after") { expect(diff).not_to be_touches("lib/a.rb", 6..6) }
  it("reads a hunk without counts") { expect(diff).to be_touches("lib/b.rb", 10..10) }
  it("does not let a removed line advance") { expect(diff).not_to be_touches("lib/b.rb", 11..11) }
  it("knows nothing of other files") { expect(diff).not_to be_touches("lib/c.rb", 1..100) }
  it("reads a path with ./ as the same file") { expect(diff).to be_touches("./lib/a.rb", 4..4) }

  it "reads an absolute path as the same file" do
    expect(diff).to be_touches(File.expand_path("lib/a.rb"), 4..4)
  end

  context "with a timestamp after the name, as diff -u and hg print it" do
    let(:text) do
      <<~DIFF
        --- a/lib/a.rb\t2026-10-02 14:00:33.158665278 +0000
        +++ b/lib/a.rb\t2026-10-02 14:00:33.158665278 +0000
        @@ -1 +1 @@
        -x = 1
        +x = 2
      DIFF
    end

    it("reads the name up to the tab") { expect(diff).to be_touches("lib/a.rb", 1..1) }
  end

  it "reads git's mnemonic prefixes" do
    mnemonic = described_class.new(text.gsub("+++ b/", "+++ w/").gsub("--- a/", "--- i/"))
    expect(mnemonic).to be_touches("lib/a.rb", 4..4)
  end

  it "reads past a byte that is not UTF-8" do
    stray = described_class.new("#{text}-old \xff\n".b)
    expect(stray).to be_touches("lib/b.rb", 10..10)
  end

  it "reads standard input for -" do
    allow($stdin).to receive(:read).and_return(text)
    expect(described_class.read("-")).to be_touches("lib/b.rb", 10..10)
  end
end
