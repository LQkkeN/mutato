# frozen_string_literal: true

require "coverage"

module Mutato
  class Boot
    def initialize(selection, console)
      @selection = selection
      @console = console
      @output = nil
    end

    def suite
      adapter = booted
      # What booting executed, before any test ran.
      executed = Coverage.peek_result
      started = Clock.now
      measured = describe(measure(adapter), started)
      Suite.new(adapter:, baseline: baseline(measured, executed), options:, output:)
    end

    private

    def options
      @selection.options
    end

    def output
      @output ||= Output.new(options.out)
    end

    def booted
      started = Clock.now
      RSpecAdapter.boot(options.spec_args)
      Mutato.config.run_hooks(:after_boot)
      report_boot(started)
    end

    def report_boot(started)
      count = RSpecAdapter.locations.size
      @console.say(
        format(
          "boot: %<seconds>.2fs, %<count>d examples loaded",
          seconds: Clock.since(started),
          count:
        )
      )
      @console.die("spec files failed to load, see the error above") if RSpecAdapter.load_failed?
      @console.die(no_tests) if count.zero?
      RSpecAdapter
    end

    def no_tests
      return "the suite is Minitest; mutato is RSpec-only" if defined?(Minitest::Test)

      "no tests loaded from #{options.spec_args.join(" ")}"
    end

    def measure(adapter)
      log = output.log_path("baseline")
      Mutato.config.run_hooks(:before_mutant)
      check(Child.run(log:) { adapter.baseline(@selection.prefixes) }, log)
    end

    def check(measured, log)
      return measured if measured.is_a?(Measure)

      @console.die("baseline crashed: #{measured.inspect}, see #{log}")
    end

    def describe(measured, started)
      @console.say(measured.summary(Clock.since(started)))
      failed = measured.failed
      if failed.any?
        @console.say("baseline: #{failed.size} failing tests excluded: #{failed.first(5)}")
      end
      @console.die("baseline: nothing passed") if measured.all_failed?
      measured
    end

    def baseline(measured, executed)
      # With autoloading, a file may load first in a test.
      loaded = executed.keys.to_set.merge(measured.seen)
      measured.baseline(
        locations: RSpecAdapter.locations,
        boot_lines: boot_lines(executed),
        loaded_files: loaded
      )
    end

    def boot_lines(executed)
      prefixes = @selection.prefixes
      hits = executed.flat_map do |path, data|
        path.start_with?(*prefixes) ? Hits.keys(path, data) : []
      end
      hits.to_set
    end
  end
end
