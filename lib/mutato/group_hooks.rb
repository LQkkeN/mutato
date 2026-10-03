# frozen_string_literal: true

module Mutato
  # Lines a before(:all) hook hits count for every example of its group.
  class GroupHooks
    def self.assign(ids, line_map)
      yield.each { |key| line_map[key].concat(ids) }
    end

    def self.all_ids
      RSpec.world.example_groups.flat_map(&:descendant_filtered_examples).map(&:id)
    end

    def initialize
      @pending = false
      @suite = true
      @ids = {}
    end

    # At the first group: what before(:suite) ran, which every example runs after.
    def credit_suite(line_map, &)
      return unless @suite

      @suite = false
      GroupHooks.assign(GroupHooks.all_ids, line_map, &)
    end

    def expect_hooks
      @pending = true
    end

    def credit(group, line_map, &)
      return unless @pending

      @pending = false
      GroupHooks.assign(served(group), line_map, &)
    end

    private

    def served(group)
      @ids[group] ||= group.parent_groups.flat_map(&:descendant_filtered_examples).map(&:id).uniq
    end
  end
end
