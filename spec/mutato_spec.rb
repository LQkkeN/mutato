# frozen_string_literal: true

require_relative "spec_helper"

# What a project's .mutato.rb calls.
RSpec.describe Mutato do
  let(:config) { Mutato::Config.new }

  before { allow(described_class).to receive(:config).and_return(config) }

  %i[before_fork after_fork after_boot before_mutant].each do |hook|
    it "registers a #{hook} hook" do
      block = -> {}
      described_class.public_send(hook, &block)
      expect(config.hooks[hook]).to eq([block])
    end
  end

  it "registers a skip with its reason" do
    described_class.skip("App#call", "plumbing")
    expect(config.skip_reason("App#call")).to eq("plumbing")
  end

  it "registers arid names" do
    described_class.arid(:say, "UI")
    expect(config).to be_arid("UI")
  end
end
