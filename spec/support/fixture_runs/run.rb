# frozen_string_literal: true

require "json"

module FixtureRuns
  # One run of the CLI on the fixture project: its output, exit status and
  # output directory.
  Run = Data.define(:stdout, :stderr, :status, :out) do
    def self.labels(outcomes)
      outcomes.map { |outcome| outcome.fetch("label") }
    end

    def outcomes
      JSON.parse(File.read(File.join(out, "outcomes.json")))
    end

    # "lib/outcomes.rb:13 delete statement `i += 1`" for that mutant.
    def self.place(outcome)
      "#{outcome.fetch("file")}:#{outcome.fetch("line")} #{outcome.fetch("description")}"
    end

    def outcome_by_place
      outcomes.to_h { |outcome| [Run.place(outcome), outcome.fetch("outcome")] }
    end

    def labels_by_outcome
      grouped = outcomes.group_by { |outcome| outcome.fetch("outcome") }
      grouped.transform_values { |group| Run.labels(group) }
    end

    def file(name)
      File.read(File.join(out, name))
    end
  end
  public_constant :Run
end
