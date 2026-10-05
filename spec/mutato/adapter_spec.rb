# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe Mutato::Adapter do
  [Mutato::RSpecAdapter, Mutato::MinitestAdapter].each do |adapter|
    it "has #{adapter} answer every call" do
      expect(described_class::CALLS.reject { |call| adapter.respond_to?(call) }).to be_empty
    end
  end

  it "has the stand-in for a booted suite answer a run's calls" do
    expect(described_class::RUN.reject { |call| OneTestSuite.new.respond_to?(call) }).to be_empty
  end
end
