# frozen_string_literal: true

require "minitest"
require "stringio"
require_relative "../spec_helper"

# The adapter in this process, on the fixture; boot's process-wide setup is left out.
RSpec.describe Mutato::MinitestAdapter do
  let(:fixture) { File.expand_path("../fixtures/minitest", __dir__) }
  let(:sample) { File.join(fixture, "test", "sample_test.rb") }
  let(:printed) { StringIO.new }

  # A failing test is printed into the log, which is stdout.
  def printing
    stdout = $stdout
    $stdout = printed
    yield
  ensure
    $stdout = stdout
  end

  before do
    described_class.require_minitest
    described_class.take([File.join(fixture, "test")])
  end

  describe ".take" do
    let(:broken) { File.join(fixture, "broken") }

    it("loads the files") { expect(described_class).not_to be_load_failed }

    it "says why a file fails to load" do
      expect { described_class.take([broken]) }
        .to output(/broken on purpose/).to_stderr
    end

    it "remembers that a file failed to load" do
      expect { described_class.take([broken]) }
        .to change(described_class, :load_failed?).to(true).and(output.to_stderr)
    end

    it "leaves mutato's frames out of failure locations" do
      own = File.expand_path("../../lib/mutato/run.rb:1", __dir__)
      expect(Minitest.backtrace_filter.filter([own, "#{sample}:5"])).to eq(["#{sample}:5"])
    end
  end

  describe ".locations" do
    let(:locations) { described_class.locations }

    it "names a test by its class and method" do
      expect(locations.fetch("SampleTest#test_passes")).to eq(sample)
    end

    it "keeps two classes of one name apart" do
      expect(locations.keys.grep(/\AShared#test_0001_counts/).size).to eq(2)
    end
  end

  describe ".baseline" do
    let(:tally) { Mutato::Tally.new(Hash.new { |hash, key| hash[key] = [] }, {}, [], Set.new, 0) }
    let(:measure) { printing { described_class.baseline([fixture]) } }

    before do
      allow(Mutato::Tally).to receive(:fresh).and_return(tally)
      allow(tally).to receive(:read).and_return(["lib/x.rb:3"])
      allow(described_class).to receive(:child_done)
    end

    it("fails") { expect(measure.status).to eq(1) }

    it "passes when every test passes" do
      allow(described_class).to receive(:passed?).and_return(true)
      expect(measure.status).to eq(0)
    end

    it "fails only the failing test, a skip passing" do
      expect(measure.failed).to eq(["SampleTest#test_fails"])
    end

    it "prints the failure" do
      expect { measure }
        .to change(printed, :string).to(/on purpose/)
    end

    it "credits every test with the lines it ran" do
      expect(measure.line_map.fetch("lib/x.rb:3")).to include(
        "SampleTest#test_passes",
        "SampleTest#test_skips"
      )
    end

    it "runs the after_run blocks a child may run" do
      measure
      expect(described_class).to have_received(:child_done)
    end
  end

  describe ".run" do
    let(:failing) do
      printing do
        described_class.run(%w[SampleTest#test_passes SampleTest#test_fails])
      end
    end
    let(:passing) { described_class.run(%w[SampleTest#test_passes SampleTest#test_skips]) }

    before { allow(described_class).to receive(:child_done) }

    it("names the first failure") { expect(failing.failing).to eq("SampleTest#test_fails") }
    it("fails") { expect(failing.status).to eq(1) }

    it "ran the tests up to it" do
      expect(failing.ran).to eq(%w[SampleTest#test_passes SampleTest#test_fails])
    end

    it "prints the failure" do
      expect { failing }
        .to change(printed, :string).to(/test_fails.*on purpose/m)
    end

    it "runs a test inside its class's hooks, as before_all is" do
      expect(described_class.run(%w[HookedTest#test_sees_the_class_hook]).status).to eq(0)
    end

    it "passes when every test passes or skips" do
      expect(passing.outcome).to include(outcome: :missed)
    end

    it "knows the test it is running" do
      passing
      expect(described_class.current).to eq("SampleTest#test_skips")
    end

    it "leaves the after_run blocks to its caller, outside the watchdog's time" do
      passing
      expect(described_class).not_to have_received(:child_done)
    end
  end

  describe ".suite_done" do
    let(:ran) { [] }

    before do
      blocks = [-> { ran << :first }, -> { ran << :second }]
      allow(Minitest).to receive(:class_variable_get).with(:@@after_run).and_return(blocks)
    end

    it "runs Minitest's after_run blocks, the last registered first" do
      described_class.suite_done
      expect(ran).to eq(%i[second first])
    end

    it "runs the other blocks when one fails" do
      blocks = [-> { ran << :first }, -> { raise "gone" }]
      allow(Minitest).to receive(:class_variable_get).with(:@@after_run).and_return(blocks)
      allow($stderr).to receive(:write)
      described_class.suite_done
      expect(ran).to eq([:first])
    end

    it "does nothing where minitest never loaded" do
      hide_const("Minitest")
      expect { described_class.suite_done }
        .not_to output.to_stderr
    end

    it "reports a failing block instead of raising" do
      failing = [-> { raise "gone" }]
      allow(Minitest).to receive(:class_variable_get).with(:@@after_run).and_return(failing)
      expect { described_class.suite_done }
        .to output(/Minitest.after_run: .*gone/m).to_stderr
    end
  end

  describe ".child_done" do
    before { allow(described_class).to receive(:suite_done) }

    after { Minitest.allow_fork = false }

    it "leaves the after_run blocks to the parent, as Minitest does in a fork" do
      described_class.child_done
      expect(described_class).not_to have_received(:suite_done)
    end

    it "runs them in a child when the project allows it" do
      Minitest.allow_fork = true
      described_class.child_done
      expect(described_class).to have_received(:suite_done)
    end
  end

  describe ".require_minitest" do
    # Off only now: loading the fixture calls autorun, which turns them on.
    around do |example|
      deprecated = Warning[:deprecated]
      example.run
    ensure
      Warning[:deprecated] = deprecated
    end

    before { Warning[:deprecated] = false }

    it "keeps autorun from running the tests again" do
      Minitest.autorun
      expect(Minitest.class_variable_get(:@@installed_at_exit)).to be(false)
    end

    it "keeps autorun turning on deprecation warnings" do
      expect { Minitest.autorun }
        .to change { Warning[:deprecated] }
        .to(true)
    end

    it("fixes the seed") { expect(Minitest.seed).to eq(0) }

    it "stops in one line when the bundle has no minitest" do
      allow(described_class).to receive(:require).with("minitest").and_raise(LoadError)
      expect { described_class.require_minitest }
        .to raise_error(Mutato::Abort, /no minitest to load/)
    end
  end
end
