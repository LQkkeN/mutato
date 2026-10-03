# frozen_string_literal: true

module Mutato
  class CoverageListener
    Tally = Struct.new(:line_map, :durations, :failed, :seen, :began) do
      def self.fresh
        new(Hash.new { |hash, key| hash[key] = [] }, {}, [], Set.new, Clock.now)
      end

      def finish(example, seconds, hits)
        id = example.id
        durations[id] = seconds
        failed << id if example.execution_result.status == :failed
        hits.each { |key| line_map[key] << id }
      end

      # Read right after the run: its time less the tests' is the hooks'. A Hash with a
      # default block cannot be marshalled.
      def to_h
        hooks = [Clock.since(began) - durations.values.sum, 0].max
        super.except(:began).merge(line_map: line_map.to_a.to_h, hooks:)
      end
    end
    public_constant :Tally
  end
end
