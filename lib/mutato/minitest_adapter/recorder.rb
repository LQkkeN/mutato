# frozen_string_literal: true

module Mutato
  module MinitestAdapter
    # Minitest's reporter interface, keeping the result a one-test run records.
    Recorder = Struct.new(:result) do
      # By the class's own runner, so that its class-level hooks, such as before_all, run too.
      def self.result_of(klass, name)
        only = /\A#{Regexp.escape(name)}\z/
        recorder = new
        if Gem::Version.new(Minitest::VERSION) >= Gem::Version.new("6")
          klass.run_suite(recorder, include: only)
        else
          klass.run(recorder, filter: only)
        end
        recorder.result
      end

      def prerecord(_klass, _name); end

      def record(result)
        self.result = result
      end

      def passed?
        result.nil? || result.passed?
      end
    end
    public_constant :Recorder
  end
end
