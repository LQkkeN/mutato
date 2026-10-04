# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe Mutato::Integrations do
  let(:active_record) { described_class::ActiveRecord }
  let(:sequel_database) do
    Struct.new(:disconnected) do
      def disconnect = self.disconnected = true
    end
  end

  before do
    allow(active_record).to receive(:before_fork)
    allow(active_record).to receive(:after_fork)
  end

  it "disconnects Sequel's databases before a fork" do
    database = sequel_database.new(false)
    stub_const("Sequel::DATABASES", [database])
    expect { described_class.before_fork }
      .to change(database, :disconnected).to(true)
  end

  it "readies Active Record's pools before a fork" do
    stub_const("ActiveRecord::Base", Class.new)
    described_class.before_fork
    expect(active_record).to have_received(:before_fork)
  end

  it "restores them after one" do
    stub_const("ActiveRecord::Base", Class.new)
    described_class.after_fork
    expect(active_record).to have_received(:after_fork)
  end

  it "leaves Active Record alone after a fork where it is not loaded" do
    described_class.after_fork
    expect(active_record).not_to have_received(:after_fork)
  end

  describe ".install" do
    let(:config) { Mutato::Config.new }

    before do
      allow(Mutato).to receive(:config).and_return(config)
      allow(described_class).to receive(:before_fork)
      allow(described_class).to receive(:after_fork)
      described_class.install
    end

    it "hooks its before_fork to every fork" do
      config.run_hooks(:before_fork)
      expect(described_class).to have_received(:before_fork)
    end

    it "hooks its after_fork to every child" do
      config.run_hooks(:after_fork)
      expect(described_class).to have_received(:after_fork)
    end
  end

  it "leaves Active Record alone where a gem defines only its namespace" do
    stub_const("ActiveRecord", Module.new)
    described_class.before_fork
    expect(active_record).not_to have_received(:before_fork)
  end
end
