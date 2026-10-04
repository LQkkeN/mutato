# frozen_string_literal: true

require "prism"
require_relative "genre"

module Mutato
  module Genres
    class Statements < Genre
      LOOPS = [
        Prism::WhileNode,
        Prism::UntilNode,
        Prism::ForNode,
        Prism::BlockNode,
        Prism::LambdaNode
      ].freeze
      # `n += 1` and `n ||= x` read n as well.
      READS = [
        Prism::LocalVariableReadNode,
        Prism::LocalVariableOperatorWriteNode,
        Prism::LocalVariableOrWriteNode,
        Prism::LocalVariableAndWriteNode
      ].freeze
      EFFECTS = [
        Prism::YieldNode,
        Prism::SuperNode,
        Prism::ForwardingSuperNode,
        Prism::InstanceVariableWriteNode,
        Prism::ClassVariableWriteNode,
        Prism::GlobalVariableWriteNode
      ].freeze
      private_constant :LOOPS, :READS, :EFFECTS

      # Computing it has no effect: literals, reads, and operators between them.
      def self.pure?(value)
        Nodes.each_node(value).all? do |node|
          node.is_a?(Prism::CallNode) ? Nodes.binary_operator?(node) : !Nodes.one_of?(node, EFFECTS)
        end
      end

      def self.around?(node, offset)
        span = node.location
        Nodes.one_of?(node, LOOPS) && (span.start_offset...span.end_offset).cover?(offset)
      end

      # Deleting these changes nothing a test can see.
      def self.keep?(statement)
        return true if Arid.arid_node?(statement) || Nodes.one_of?(statement, Nodes::LITERALS)

        statement.is_a?(Prism::DefNode) || MemoGuard.match?(statement)
      end

      def mutate(node)
        spared = visitor.walk.spared
        return if spared.include?(node)

        statements = node.body
        statements.each do |statement|
          consider(statement, statements.last) unless spared.include?(statement)
        end
      end

      private

      def consider(statement, valued)
        return visitor.walk.dead << statement if dead_store?(statement, valued)

        delete(statement) unless Statements.keep?(statement)
      end

      def delete(statement)
        visitor.walk.deleted << statement
        change = Change.whole(
          statement,
          "nil",
          "delete statement `#{Nodes.compact(statement.slice)}`"
        )
        visitor.with_statement(statement) do
          emit(:statement, change.covering(Nodes.extent(statement, source)))
        end
      end

      # A local store ending its list is the list's value; of ivars, only initialize's `@x = nil`.
      def dead_store?(statement, valued)
        case statement
        when Prism::LocalVariableWriteNode then !statement.equal?(valued) && dead_local?(statement)
        when Prism::InstanceVariableWriteNode then initial_nil?(statement)
        when Prism::CallNode then Nodes.nil_store?(statement)
        else false
        end
      end

      def dead_local?(write)
        unread_local?(write) && Statements.pure?(write.value)
      end

      def initial_nil?(write)
        visitor.subject.name == :initialize && write.value.is_a?(Prism::NilNode)
      end

      # In a loop or block, a read earlier in the body sees the write on the next pass.
      def unread_local?(write)
        from = outermost_loop_start(write) || write.location.end_offset
        reads_of(write.name).none? { |read| (from..).cover?(read.location.start_offset) }
      end

      def outermost_loop_start(write)
        offset = write.location.start_offset
        nodes = Nodes.each_node(visitor.subject.node)
        starts = nodes.filter_map do |node|
          node.location.start_offset if Statements.around?(node, offset)
        end
        starts.min
      end

      def reads_of(name)
        Nodes.each_node(visitor.subject.node).select do |node|
          Nodes.one_of?(node, READS) && node.name == name
        end
      end
    end
  end
end
