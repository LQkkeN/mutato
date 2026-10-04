# frozen_string_literal: true

require_relative "../../spec_helper"

RSpec.describe Mutato::MinitestAdapter::Files do
  let(:tests) { File.expand_path("../../fixtures/minitest/test", __dir__) }
  let(:sample) { File.join(tests, "sample_test.rb") }
  let(:shared) { File.join(tests, "spec_shared.rb") }
  let(:all) { [File.join(tests, "hooked_test.rb"), sample, shared] }

  it "takes a directory's test and spec files in order, and nothing else" do
    expect(described_class.find([tests])).to eq(all)
  end

  it("takes a file as it is") { expect(described_class.find([sample])).to eq([sample]) }

  it "expands a glob" do
    expect(described_class.find([File.join(tests, "spec_*.rb")])).to eq([shared])
  end

  it "takes each file once" do
    expect(described_class.find([sample, tests])).to eq([sample, *(all - [sample])])
  end

  it "expands a directory a glob matches" do
    expect(described_class.find([File.join(File.dirname(tests), "te*")])).to eq(all)
  end

  it "takes a directory it would leave out when it is named" do
    expect(
      described_class.find(
        [
          File.join(tests, "dummy")
        ]
      )
    ).to eq([File.join(tests, "dummy", "dummy_test.rb")])
  end

  it "refuses a path that matches nothing" do
    expect { described_class.find([File.join(tests, "typo_tset.rb")]) }
      .to raise_error(Mutato::Abort, /no test files at .*typo_tset\.rb/)
  end

  describe ".load_path" do
    let(:base) { %w[lib test].map { |dir| File.expand_path(dir) } }

    {
      "a relative path" => "spec/fixtures/minitest/test/sample_test.rb",
      "an absolute path" => File.expand_path("spec/fixtures/minitest/test"),
      "a glob's matches" => "spec/fixtures/minitest/te*"
    }.each do |what, arg|
      it "adds the first directory of #{what} below the current one" do
        expect(described_class.load_path([arg])).to eq(base + [File.expand_path("spec")])
      end
    end

    it "adds a directory outside the current one itself" do
      outside = Scratch.dir
      expect(described_class.load_path([outside])).to eq(base + [outside])
    end

    it "adds the directory of a file outside the current one" do
      outside = Scratch.dir
      File.write(File.join(outside, "a_test.rb"), "")
      expect(described_class.load_path([File.join(outside, "a_test.rb")])).to eq(base + [outside])
    end

    it "adds nothing for a path that matches nothing" do
      expect(described_class.load_path(%w[no/such])).to eq(base)
    end
  end
end
