# frozen_string_literal: true

module Mutato
  Measure = Data.define(:status, :line_map, :durations, :failed, :seen, :hooks) do
    # A set: an array here would take a minute on a large suite.
    def self.judged(ids, judges)
      ids.select { |id| judges.include?(id) }
    end

    def summary(seconds)
      format(
        "baseline: status %<status>d, %<seconds>.2fs, %<lines>d covered lines, %<tests>d tests",
        status:,
        seconds:,
        lines: line_map.size,
        tests: durations.size
      )
    end

    def all_failed?
      durations.size == failed.size
    end

    # Only tests that ran and passed can judge a mutant; a group hook may credit others.
    def baseline(**rest)
      judges = (durations.keys - failed).to_set
      Baseline.new(
        line_map: line_map.transform_values { |ids| Measure.judged(ids, judges) },
        durations:,
        order: durations.each_key.with_index.to_h,
        hooks:,
        **rest
      )
    end
  end
  public_constant :Measure
end
