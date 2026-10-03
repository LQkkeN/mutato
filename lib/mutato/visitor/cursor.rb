# frozen_string_literal: true

module Mutato
  class Visitor
    # Inside a block, `outer` stays the statement outside it, whose tests judge the mutant.
    Cursor = Data.define(:statement, :outer, :in_block) do
      def self.start
        new(statement: nil, outer: nil, in_block: false)
      end

      def at(statement)
        with(statement:, outer: in_block ? outer : statement)
      end

      def inside_block
        with(in_block: true)
      end

      def outer_lines(node)
        return unless in_block

        location = (outer || node).location
        location.start_line..location.end_line
      end
    end
    private_constant :Cursor
  end
end
