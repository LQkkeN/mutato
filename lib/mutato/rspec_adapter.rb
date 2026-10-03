# frozen_string_literal: true

require "coverage"
require_relative "rspec_adapter/progress"
require_relative "rspec_adapter/result"

module Mutato
  # RSpec is one per process, so this is a module, not a class.
  module RSpecAdapter
    module_function

    def boot(args)
      # Cached iseqs cannot carry coverage.
      ENV["DISABLE_BOOTSNAP_COMPILE_CACHE"] ||= "1"
      start_coverage
      # Here, not at load: the project's bundle provides rspec.
      require "rspec/core"
      setup(RSpec::Core::Runner.new(RSpec::Core::ConfigurationOptions.new(args)))
    end

    # Before spec_helper, so files load instrumented; lines only, as method counters slow calls.
    def start_coverage
      Coverage.start(lines: true) unless Coverage.running?
    end

    def setup(runner)
      @runner = runner
      runner.setup($stderr, $stdout)
      RSpec.configuration.backtrace_exclusion_patterns << %r{/mutato/}
    end

    def locations
      RSpec.world.all_examples.to_h { |example| [example.id, example.metadata.fetch(:file_path)] }
    end

    # A SyntaxError sets rspec_is_quitting, any other load error wants_to_quit.
    def load_failed?
      world = RSpec.world
      world.rspec_is_quitting || world.wants_to_quit
    end

    def current
      @progress&.current
    end

    def stop
      RSpec.world.wants_to_quit = true
    end

    # Child only.
    def baseline(prefixes)
      listener = CoverageListener.new(prefixes)
      RSpec.configuration.reporter.register_listener(listener, *CoverageListener::EVENTS)
      quiet(fail_fast: false)
      Coverage.result(stop: false, clear: true)
      Measure.new(status: run_all, **listener.tally.to_h)
    end

    # Child only. Stops at the first failure.
    def run(ids)
      prepare(ids)
      Result.new(
        status: run_all,
        outside: RSpec.world.non_example_failure,
        failing: first_failure,
        ran: @progress.ran
      )
    end

    def prepare(ids)
      quiet(fail_fast: 1)
      order(ids.each_with_index.to_h)
      filter(ids.to_set)
      watch
    end

    def watch
      @progress = Progress.new
      RSpec.configuration.reporter.register_listener(@progress, :example_started)
    end

    def run_all
      @runner.run_specs(RSpec.world.ordered_example_groups)
    end

    def first_failure
      RSpec.configuration.reporter.failed_examples.first&.id
    end

    # No status file, a fresh clock, and fail_fast forced: --fail-fast in .rspec is forced too.
    def quiet(fail_fast:)
      configuration = RSpec.configuration
      configuration.example_status_persistence_file_path = nil
      configuration.start_time = Time.now
      configuration.force(fail_fast:)
    end

    def order(rank)
      RSpec.configuration.register_ordering(:global) { |items| ordered(items, rank) }
    end

    def ordered(items, rank)
      items.sort_by { |item| rank_of(item, rank) }
    end

    def rank_of(item, rank)
      return rank.fetch(item.id, Float::INFINITY) if item.is_a?(RSpec::Core::Example)

      ranks = item.descendant_filtered_examples.map { |example| rank.fetch(example.id, Float::INFINITY) }
      ranks.min || Float::INFINITY
    end

    def filter(wanted)
      filtered_examples.each_value { |examples| keep(examples, wanted) }
    end

    # Filtered examples are computed on demand, group by group.
    def filtered_examples
      world = RSpec.world
      filtered = world.filtered_examples
      world.example_groups.flat_map(&:descendants).each { |group| filtered[group] }
      filtered
    end

    def keep(examples, wanted)
      examples.select! { |example| wanted.include?(example.id) }
    end
  end
end
