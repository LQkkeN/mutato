# frozen_string_literal: true

module Mutato
  module Mode
    module Run
      module_function

      def todo(selection)
        selection.mutations
      end

      def exit_code(outcomes)
        Mode.missed(outcomes).any? ? 2 : 0
      end

      def summary(outcomes)
        lines = Mode.missed(outcomes).map do |outcome|
          "  #{outcome.fetch(:id)}  #{outcome.fetch(:label)}#{flaky_note(outcome)}"
        end
        lines.empty? ? [] : ["\nMISSED:", *lines]
      end

      def flaky_note(outcome)
        excluded = outcome.fetch(:flaky, [])
        "  (#{excluded.size} flaky tests excluded)" if excluded.any?
      end

      def annotate(outcomes, console, format)
        Annotations.new(console).show(outcomes, format)
      end
    end
  end
end
