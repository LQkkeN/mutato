# frozen_string_literal: true

require "open3"
require "tmpdir"
require_relative "fixture_runs/run"

# A CLI run that boots a test framework runs as a subprocess on a fixture
# project, once per distinct command line; examples share the result.
module FixtureRuns
  FIXTURES = File.expand_path("../fixtures", __dir__)
  EXE = File.expand_path("../../exe/mutato", __dir__)
  private_constant :FIXTURES, :EXE

  module_function

  # On the calc fixture, the one most specs use.
  def run(*args, stdin: "", env: {})
    call(["calc", args, stdin, env])
  end

  def run_in(fixture, *args)
    call([fixture, args, "", {}])
  end

  def path(*parts)
    File.join(FIXTURES, "calc", *parts)
  end

  def within(&)
    Dir.chdir(path, &)
  end

  # The two guards of Fixture::Calc#clamp as a unified diff, as any VCS prints it.
  def clamp_diff
    File.read(path("clamp.diff"))
  end

  # A mutant with the lines whose tests judge it, as the recorded listing has it.
  def recorded_line(mutation)
    outer = mutation.outer_lines
    blocks = mutation.subject.block_lines
    via = " via #{outer.begin}-#{outer.end}" if outer
    span = "lines #{mutation.start_line}-#{mutation.end_line}#{via}"
    "#{mutation.listing}  #{span}#{" blocks #{blocks.join(",")}" if blocks.any?}"
  end

  def call(key)
    @runs ||= {}
    @runs[key] ||= capture(key)
  end

  def capture(key)
    out = Dir.mktmpdir("mutato")
    at_exit { FileUtils.remove_entry(out) }
    Run.new(out:, **invoke(out, key))
  end

  # Every run gets the step summary file and a scratch directory of its own.
  def invoke(out, key)
    fixture, args, stdin, extra = key
    env = {
      "GITHUB_STEP_SUMMARY" => File.join(out, "summary.md"),
      "FIXTURE_TMP" => out
    }.merge(extra)
    command = ["ruby", EXE, *args, "--out", out]
    stdout, stderr, status = Open3.capture3(
      env,
      *command,
      stdin_data: stdin,
      chdir: File.join(FIXTURES, fixture)
    )
    { stdout:, stderr:, status: }
  end
end
