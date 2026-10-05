# frozen_string_literal: true

require_relative "abort"
require_relative "adapter"
require_relative "annotations"
require_relative "baseline"
require_relative "boot"
require_relative "campaign"
require_relative "child"
require_relative "clock"
require_relative "console"
require_relative "coverage_listener"
require_relative "covering"
require_relative "diff"
require_relative "equivalence"
require_relative "experience"
require_relative "flags"
require_relative "group_hooks"
require_relative "hits"
require_relative "measure"
require_relative "minitest_adapter"
require_relative "mode"
require_relative "options"
require_relative "output"
require_relative "report"
require_relative "rspec_adapter"
require_relative "run"
require_relative "selection"
require_relative "session"
require_relative "soft_timeout"
require_relative "suite"
require_relative "trial"
require_relative "watchdog"

module Mutato
  class CLI
    USAGE = <<~USAGE
      usage: mutato list|run|control PATH... [options]
        list     the mutants that would be tried, without running anything
        run      baseline, then every mutant; survivors are the output
        control  reinstall every method unchanged; all must come out missed
      options:
        -h, --help  -v, --version  this text, the version
        --spec ARGS                rspec arguments: paths, --tag, ... (default spec)
        --test PATHS               Minitest files, directories, globs (default test)
        --config FILE              hooks and skips (default .mutato.rb)
        --diff FILE|-              only mutate lines a unified diff adds or changes
        --format github|plain      survivors as annotations or path:line:col lines
        --limit N  --sample N  --genre a,b  --only ID,ID
        --out DIR (default mutato.out)  --timeout-min SECONDS (default 10)
    USAGE
    MODES = { "run" => Mode::Run, "control" => Mode::Control }.freeze
    COMMANDS = ["list", *MODES.keys].freeze
    private_constant :USAGE, :MODES, :COMMANDS

    # Returns the exit code; an Abort from anywhere, flag parsing included, ends here.
    def self.call(argv, console: Console.new)
      new(argv, console:).call
    rescue Abort => error
      console.say(error.message)
      error.code
    ensure
      console.flush
    end

    def initialize(argv, console:)
      @console = console
      # Loaded test code may rewrite ARGV.
      argv = argv.dup
      @options = parse(argv)
      @command = argv.shift
      @paths = argv.freeze
    end

    def call
      return show(info) if info

      prepare
      dispatch(Selection.new(@paths, @options))
    end

    private

    def info
      return USAGE if @options.help

      "mutato #{VERSION}" if @options.version
    end

    def prepare
      check_paths
      load_config
      ARGV.clear
    end

    # OptionParser reports a bad flag by raising; the user gets one line.
    def parse(argv)
      Options.parse(argv)
    rescue OptionParser::ParseError => error
      @console.die("#{error.message}; mutato --help lists the options")
    end

    def show(text)
      @console.out(text)
      0
    end

    def check_paths
      @console.die(USAGE) unless COMMANDS.include?(@command) && @paths.any?
      missing = @paths.reject { |path| File.exist?(path) }
      @console.die("no such path: #{missing.join(", ")}") if missing.any?
    end

    def load_config
      named = @options.config
      config = named || ".mutato.rb"
      exists = File.exist?(config)
      @console.die("no such config: #{config}") if named && !exists
      load config if exists
    end

    def dispatch(selection)
      return list(selection) if @command == "list"

      Session.new(MODES.fetch(@command), selection, @console).call
    end

    def list(selection)
      mutations = selection.chosen(selection.mutations)
      print_listing(mutations)
      @console.say(*selection.summary(mutations))
      0
    end

    # On stdout, and out before the summary follows on stderr.
    def print_listing(mutations)
      mutations.each { |mutation| @console.out(mutation.listing) }
      @console.flush
    end
  end
end
