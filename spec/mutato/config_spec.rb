# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe Mutato::Config do
  subject(:config) { described_class.new }

  describe "#skip_reason" do
    before do
      config.skip("App::Calc#add", "exact")
      config.skip("App::Calc#ok?", "exact too")
      config.skip(/\AApp::Routes/, "pattern")
    end

    it("matches a name exactly") { expect(config.skip_reason("App::Calc#add")).to eq("exact") }
    it("does not match a name that merely starts the same") { expect(config.skip_reason("App::Calc#add_all")).to be_nil }
    it("takes a name literally, question mark included") { expect(config.skip_reason("App::Calc#ok")).to be_nil }
    it("matches a pattern") { expect(config.skip_reason("App::Routes#index")).to eq("pattern") }
    it("gives nothing for the rest") { expect(config.skip_reason("App::Other#thing")).to be_nil }
  end

  describe "#arid?" do
    before { config.arid(:say, "UI") }

    it("knows a method by symbol") { expect(config).to be_arid(:say) }
    it("knows a constant by name") { expect(config).to be_arid("UI") }
    it("knows nothing else") { expect(config).not_to be_arid(:puts) }
  end

  describe "#run_hooks" do
    it "runs each hook registered under the name, in order" do
      ran = []
      config.hooks[:after_boot] << -> { ran << 1 } << -> { ran << 2 }
      config.run_hooks(:after_boot)
      expect(ran).to eq([1, 2])
    end

    it "runs nothing for a name without hooks" do
      expect { config.run_hooks(:before_fork) }
        .not_to change(config, :hooks)
    end
  end
end
