# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe Mutato::Mode do
  let(:outcomes) do
    %i[missed unjudged caught uncovered load-time unloaded timeout].map do |name|
      Records.outcome(name)
    end
  end

  { Mutato::Mode::Run => :mutations, Mutato::Mode::Control => :controls }.each do |mode, todo|
    it "has #{mode.name.split("::").last} try the selection's #{todo}" do
      expect(mode.todo(instance_double(Mutato::Selection, todo => [:all]))).to eq([:all])
    end
  end

  it "takes missed and unjudged mutants for survivors" do
    survivors = described_class.missed(outcomes)
    expect(survivors.map { |record| record.fetch(:outcome) }).to eq(%i[missed unjudged])
  end

  it "takes a mutant some test ran as exercised" do
    expect(described_class).to be_exercised(Records.outcome(:missed))
  end

  it "takes a mutant no test ran as not exercised" do
    expect(described_class).not_to be_exercised(Records.outcome(:uncovered, examples: 0))
  end

  it "fails a control on every outcome but missed, uncovered, load-time and unloaded" do
    failures = described_class.failed_controls(outcomes)
    expect(failures.map { |record| record.fetch(:outcome) }).to eq(%i[unjudged caught timeout])
  end
end
