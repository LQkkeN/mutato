# frozen_string_literal: true

require "minitest"
require_relative "../../spec_helper"

RSpec.describe Mutato::MinitestAdapter::Recorder do
  # Records which of Minitest's class-level runners ran it, with which filter.
  let(:klass) do
    Class.new do
      def self.run_suite(reporter, include:) = reporter.record([:run_suite, include])
      def self.run(reporter, filter:) = reporter.record([:run, filter])
    end
  end

  describe ".result_of" do
    { "6.0.0" => :run_suite, "5.25.4" => :run }.each do |version, runner|
      it "runs one test by Minitest #{version}'s #{runner}" do
        stub_const("Minitest::VERSION", version)
        expect(described_class.result_of(klass, "test_a?")).to eq([runner, /\Atest_a\?\z/])
      end
    end
  end

  describe "#passed?" do
    it("passes before anything is recorded") { expect(described_class.new).to be_passed }

    it "fails once a failure is recorded" do
      recorder = described_class.new
      recorder.record(instance_double(Minitest::Result, passed?: false))
      expect(recorder).not_to be_passed
    end
  end
end
