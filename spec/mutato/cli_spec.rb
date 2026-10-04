# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe Mutato::CLI, :subprocess do
  shared_examples "a refusal" do |reason|
    it("fails") { expect(run.status.exitstatus).to eq(1) }
    it("says why") { expect(run.stderr).to include(reason) }
  end

  describe "run" do
    let(:run) { FixtureRuns.run("run", "lib") }
    let(:labels) { run.labels_by_outcome }

    it("exits 2 when mutants survive") { expect(run.status.exitstatus).to eq(2), run.stderr }
    it("catches most mutants") { expect(labels.fetch("caught").size).to be > 10 }
    it("prints the results") { expect(run.stderr).to include("results:") }
    it("keeps the baseline's log") { expect(run.file("logs/baseline.log")).not_to be_empty }

    it "lists survivors with their ids" do
      expect(run.file("missed.txt")).to match(%r{^\h{12}  lib/calc\.rb:15:})
    end

    it "neither crashes nor loses a mutant" do
      expect(labels.keys).not_to include("crashed", "unviable", "overwritten")
    end

    it "misses the untested branch" do
      expect(labels.fetch("missed")).to include(
        a_string_including("return high if x > high"),
        a_string_including("`>` with `>=`")
      )
    end

    it "finds the private method no test reaches uncovered" do
      expect(labels.fetch("uncovered")).to include(a_string_including("secret"))
    end

    it "finds code that only runs while the suite loads" do
      expect(labels.fetch("load-time")).to include(
        a_string_including("default_limit"),
        a_string_including("x * 2"),
        a_string_including("define_double with nil")
      )
    end
  end

  describe "control" do
    let(:run) { FixtureRuns.run("control", "lib") }

    it("passes") { expect(run.status.exitstatus).to eq(0), run.stderr }
    it("says so") { expect(run.stderr).to include("control OK") }
  end

  context "without a locale, on UTF-8 source" do
    let(:unset) { { "LANG" => nil, "LC_ALL" => nil, "LC_CTYPE" => nil } }
    let(:run) { FixtureRuns.run("list", "lib", env: unset) }

    it("reads it") { expect(run.status).to be_success, run.stderr }
  end

  context "with --diff" do
    let(:run) { FixtureRuns.run("run", "lib", "--diff", "-", stdin: FixtureRuns.clamp_diff) }
    let(:outcomes) { run.outcomes }

    it("still finds the survivors") { expect(run.status.exitstatus).to eq(2), run.stderr }
    it("tries something") { expect(outcomes).not_to be_empty }

    it "mutates only the lines the diff touches" do
      expect(
        outcomes.map do |outcome|
          outcome.fetch("line")
        end
      ).to all(be_between(13, 18))
    end

    it "leaves the other methods alone" do
      expect(FixtureRuns::Run.labels(outcomes)).not_to include(a_string_including("`+` with `-`"))
    end
  end

  context "with --format github" do
    let(:run) do
      FixtureRuns.run(
        "run",
        "lib",
        "--diff",
        "-",
        "--format",
        "github",
        stdin: FixtureRuns.clamp_diff
      )
    end

    it "annotates the survivors" do
      annotation = %r{^::warning file=lib/calc\.rb,line=15,col=\d+,title=mutato::survived:}
      expect(run.stdout).to match(annotation), run.stderr
    end

    it "writes the step summary" do
      expect(run.file("summary.md")).to include("survivors", "`lib/calc.rb:15`")
    end
  end

  context "with --format plain" do
    let(:run) do
      FixtureRuns.run(
        "run",
        "lib",
        "--diff",
        "-",
        "--format",
        "plain",
        stdin: FixtureRuns.clamp_diff
      )
    end

    it "prints survivors as path:line lines" do
      expect(run.stdout).to match(%r{^lib/calc\.rb:15:\d+: survived: })
    end
  end

  describe "list" do
    let(:run) { FixtureRuns.run("list", "lib") }

    it("succeeds") { expect(run.status).to be_success }

    it "prints every mutant with its id" do
      expect(run.stdout).to match(%r{^\h{12}  lib/calc\.rb:10:\d+: \[arithmetic\] replace `\+`})
    end

    it("names the skipped methods") { expect(run.stderr).to include("skipped Fixture::Calc#abstract: template stub") }
  end

  context "with a config file" do
    let(:run) { FixtureRuns.run("list", "lib", "--config", "skip.mutato.rb") }

    it("succeeds") { expect(run.status).to be_success }
    it("reports the skip with its reason") { expect(run.stderr).to include("skipped Fixture::Calc#clamp: demo") }
    it("leaves the method out") { expect(run.stdout).not_to include("clamp") }
  end

  describe "--help" do
    let(:run) { FixtureRuns.run("--help") }
    let(:readme) { File.read(File.expand_path("../../README.md", __dir__)) }
    let(:unlisted) { run.stdout.scan(/--[a-z-]+/).uniq.reject { |option| readme.include?(option) } }

    it("succeeds") { expect(run.status).to be_success }
    it("prints the usage") { expect(run.stdout).to start_with("usage: mutato") }
    it("lists no option the README leaves out") { expect(unlisted).to be_empty }
  end

  describe "--version" do
    let(:run) { FixtureRuns.run("--version") }

    it("succeeds") { expect(run.status).to be_success }
    it("prints the version") { expect(run.stdout).to eq("mutato #{Mutato::VERSION}\n") }
  end

  context "with coverage already running, as under a coverage tool" do
    let(:early) { File.expand_path("../support/coverage_first.rb", __dir__) }
    let(:run) do
      FixtureRuns.run("list", "lib", env: { "RUBYOPT" => "#{ENV.fetch("RUBYOPT", "")} -r#{early}" })
    end

    it("still works") { expect(run.status).to be_success, run.stderr }
  end

  context "with a missing path" do
    let(:run) { FixtureRuns.run("list", "nowhere") }

    it_behaves_like "a refusal", "no such path: nowhere"
    it("says so in one line") { expect(run.stderr.lines.size).to eq(1) }
  end

  {
    "an unknown option" => [%w[list lib --bogus], "invalid option: --bogus"],
    "an option with a bad value" => [%w[list lib --limit x], "invalid argument: --limit x"],
    "a missing config" => [%w[list lib --config nowhere.rb], "no such config: nowhere.rb"],
    "an unknown mutant id" => [%w[run lib --only nope], "no such mutant: nope"],
    "an unknown command" => [%w[bogus], "usage: mutato"]
  }.each do |situation, (args, reason)|
    context "with #{situation}" do
      let(:run) { FixtureRuns.run(*args) }

      it_behaves_like "a refusal", reason
    end
  end
end
