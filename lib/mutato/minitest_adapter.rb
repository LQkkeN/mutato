# frozen_string_literal: true

require_relative "minitest_adapter/files"
require_relative "minitest_adapter/recorder"
require_relative "minitest_adapter/unframed"
require_relative "result"

module Mutato
  # One Minitest per process, so a module; each test runs alone, by its class's runner.
  module MinitestAdapter
    # mutato runs the tests; autorun keeps only its warning setting.
    NoAutorun = Module.new { define_method(:autorun) { Warning[:deprecated] = true } }
    private_constant :NoAutorun

    module_function

    def boot(args)
      prepare(args)
      take(args)
    end

    # The tests the files define; the process-wide setup is prepare's.
    def take(args)
      load_files(args)
      @tests = index
      Minitest.backtrace_filter = Unframed.new(Minitest.backtrace_filter)
    end

    def prepare(args)
      Tally.start
      ENV["PARALLEL_WORKERS"] ||= "1"
      require_minitest
      $LOAD_PATH.unshift(*Files.load_path(args))
    end

    def require_minitest
      require "minitest"
      Minitest.singleton_class.prepend(NoAutorun)
      Minitest.seed = 0
    rescue LoadError
      raise Abort.new("no minitest to load: mutato runs RSpec or Minitest", code: 1)
    end

    def load_files(args)
      @failed = false
      Files.find(args).each { |file| load_file(file) }
    end

    def load_file(file)
      require File.expand_path(file)
    rescue ScriptError, StandardError => error
      @failed = true
      # Not warn: -W0 would silence it.
      $stderr.write(error.full_message(highlight: false), "\n")
    end

    def index
      Minitest::Runnable.runnables.each_with_object({}) { |klass, tests| add(tests, klass) }
    end

    # "Class#test_name", made unique when two classes share a name.
    def add(tests, klass)
      klass.runnable_methods.each do |name|
        id = "#{klass}##{name}"
        tests[tests.key?(id) ? "#{id} (#{tests.size})" : id] = [klass, name]
      end
    end

    def locations
      @tests.to_h do |id, (klass, name)|
        [id, klass.instance_method(name).source_location&.first.to_s]
      end
    end

    def load_failed?
      @failed
    end

    def current
      @current
    end

    # The watchdog's exception ends the test, and a failed test the run.
    def stop; end

    # The after_run blocks, which exit! skips.
    def suite_done
      return unless defined?(Minitest)

      Minitest.class_variable_get(:@@after_run).reverse_each { |block| after_run(block) }
    end

    # An error in one block is the project's to read; the cleanup in the others still runs.
    def after_run(block)
      block.call
    rescue StandardError => error
      $stderr.write("Minitest.after_run: ", error.full_message(highlight: false), "\n")
    end

    # Minitest skips after_run in a forked process unless the project allows it.
    def child_done
      suite_done if Minitest.allow_fork
    end

    # Child only. after_run's time counts as hooks', as every run repeats it.
    def baseline(prefixes)
      tally = Tally.fresh
      @tests.each_key { |id| measure(id, tally, prefixes) }
      child_done
      Measure.new(**tally.to_h, status: tally.status)
    end

    def measure(id, tally, prefixes)
      started = Clock.now
      result = run_one(id)
      tally.finish(id, Clock.since(started), tally.read(prefixes))
      tally.failed << id unless passed?(result)
    end

    # Child only. Stops at the first failure.
    def run(ids)
      ran = []
      failing = ids.find { |id| failed?(id, ran) }
      Result.new(status: failing ? 1 : 0, outside: nil, failing:, ran:)
    end

    def failed?(id, ran)
      @current = id
      ran << id
      !passed?(run_one(id))
    end

    def run_one(id)
      result = Recorder.result_of(*@tests.fetch(id))
      # Into the log: no reporter prints it.
      puts(result) unless passed?(result)
      result
    end

    def passed?(result)
      result && (result.passed? || result.skipped?)
    end
  end
end
