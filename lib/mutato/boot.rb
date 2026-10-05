# frozen_string_literal: true

require "coverage"

module Mutato
  class Boot
    def initialize(selection, console)
      @selection = selection
      @console = console
      @output = nil
      @adapter = selection.options.minitest? ? MinitestAdapter : RSpecAdapter
    end

    # A run that ends while booting still ends the framework's way.
    def suite(todo)
      built(todo)
    rescue Abort
      @adapter.suite_done
      raise
    end

    private

    # Most of the tests that run the chosen mutants' lines must pass.
    def built(todo)
      booted
      # What booting executed, before any test ran.
      executed = Coverage.peek_result
      started = Clock.now
      measured = describe(measure, started, todo.flat_map(&:line_keys))
      Suite.new(adapter: @adapter, baseline: baseline(measured, executed), options:, output:)
    end

    def options
      @selection.options
    end

    def output
      @output ||= Output.new(options.out)
    end

    def booted
      started = Clock.now
      @adapter.boot(options.test_args)
      Mutato.config.run_hooks(:after_boot)
      report_boot(started)
    end

    def report_boot(started)
      count = @adapter.locations.size
      @console.say(
        format(
          "boot: %<seconds>.2fs, %<count>d tests loaded",
          seconds: Clock.since(started),
          count:
        )
      )
      @console.die("test files failed to load, see the error above") if @adapter.load_failed?
      @console.die(no_tests) if count.zero?
    end

    def no_tests
      hint = "; for Minitest, pass --test PATHS" unless options.minitest?
      "no tests loaded from #{options.test_args.join(" ")}#{hint}"
    end

    def measure
      log = output.log_path("baseline")
      Mutato.config.run_hooks(:before_mutant)
      check(Child.run(log:) { @adapter.baseline(@selection.prefixes) }, log)
    end

    def check(measured, log)
      return measured if measured.is_a?(Measure)

      @console.die("baseline crashed: #{measured.inspect}, see #{log}")
    end

    def describe(measured, started, lines)
      @console.say(measured.summary(Clock.since(started)))
      excluded(measured.failed)
      return measured unless measured.all_failed? || measured.mostly_failed?(lines)

      @console.die("baseline: too few tests pass to judge, see #{output.log_path("baseline")}")
    end

    def excluded(failed)
      return if failed.empty?

      @console.say("baseline: #{failed.size} failing tests excluded: #{failed.first(5)}")
    end

    def baseline(measured, executed)
      # With autoloading, a file may load first in a test.
      loaded = executed.keys.to_set.merge(measured.seen)
      measured.baseline(
        locations: @adapter.locations,
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
