# frozen_string_literal: true

module Mutato
  module Mode
    # A control that exercised nothing proved nothing: exit 3.
    module Control
      module_function

      def todo(selection)
        selection.controls
      end

      def exit_code(outcomes)
        return 1 if Mode.failed_controls(outcomes).any?

        outcomes.any? { |outcome| Mode.exercised?(outcome) } ? 0 : 3
      end

      def summary(outcomes)
        bad = Mode.failed_controls(outcomes)
        return verdict(outcomes) if bad.empty?

        [
          "control FAILED:",
          *bad.map do |outcome|
            "  #{outcome.fetch(:outcome)} #{outcome.fetch(:label)}"
          end
        ]
      end

      def verdict(outcomes)
        exercised = outcomes.select { |outcome| Mode.exercised?(outcome) }
        if exercised.empty?
          return ["control proved nothing: no reinstalled method was exercised by a test"]
        end

        ["control OK: #{exercised.size} of #{outcomes.size} reinstalled methods passed their tests"]
      end

      def annotate(_outcomes, _console, _format); end
    end
  end
end
