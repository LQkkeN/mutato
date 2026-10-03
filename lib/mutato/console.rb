# frozen_string_literal: true

require_relative "abort"

module Mutato
  # The real streams, duped at start: the project under test may replace $stdout.
  class Console
    def initialize(out: $stdout.dup, err: $stderr.dup)
      @out = out
      @err = err
      @err.sync = true
    end

    # Not Kernel#warn: RUBYOPT=-W0 silences that.
    def say(*lines)
      lines.each { |line| @err.puts(line) }
    end

    def out(line)
      @out.puts(line)
    end

    # CLI.call reports it and returns the code.
    def die(message, code: 1)
      raise Abort.new(message, code:)
    end

    # Stderr is unbuffered already.
    def flush
      @out.flush
    end
  end
end
