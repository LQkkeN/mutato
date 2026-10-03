# frozen_string_literal: true

require_relative "../spec_helper"

# Code run by before(:suite) is judged by every test, not by the first group's.
RSpec.describe Mutato::CLI, :subprocess do
  let(:run) { FixtureRuns.run_in("suitehook", "run", "lib/tariff.rb") }

  it "judges suite-hook code by the test that checks it" do
    configure = run.outcome_by_place.select { |place, _| place.include?(":4 ") }
    expect(configure.values.uniq).to eq(["caught"])
  end
end
