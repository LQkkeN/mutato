# frozen_string_literal: true

require_relative "mode/control"
require_relative "mode/run"

module Mutato
  module Mode
    MISSED = %i[missed unjudged].freeze
    PASSING_CONTROL = %i[missed uncovered load-time unloaded].freeze
    private_constant :MISSED, :PASSING_CONTROL

    module_function

    def missed(outcomes)
      outcomes.select { |outcome| MISSED.include?(outcome.fetch(:outcome)) }
    end

    def exercised?(outcome)
      outcome.fetch(:examples).positive?
    end

    def failed_controls(outcomes)
      outcomes.reject { |outcome| PASSING_CONTROL.include?(outcome.fetch(:outcome)) }
    end
  end
end
