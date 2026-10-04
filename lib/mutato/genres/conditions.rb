# frozen_string_literal: true

require "prism"
require_relative "genre"

module Mutato
  module Genres
    class Conditions < Genre
      CONNECTORS = { Prism::AndNode => %w[|| or], Prism::OrNode => %w[&& and] }.freeze
      LITERALS = [Prism::TrueNode, Prism::FalseNode].freeze
      private_constant :CONNECTORS, :LITERALS

      # `warn(...) unless ok`: a compound of arid parts is arid, children included.
      def branch(node)
        return :stop if Arid.arid_node?(node)

        replace(node.predicate, literals(node))
        spare_guard(node)
      end

      # The literal that skips the body: `while false`, `until true`.
      def loop(node)
        replace(node.predicate, node.is_a?(Prism::WhileNode) ? %w[false] : %w[true])
      end

      def connector(node)
        operator = node.operator_loc
        spelled = operator.slice
        replacement = CONNECTORS.fetch(node.class)[spelled.match?(/\A\w/) ? 1 : 0]
        emit(
          :condition,
          Change.whole(
            node,
            replacement,
            "replace `#{spelled}` with `#{replacement}`"
          ).at(operator)
        )
      end

      private

      def replace(predicate, literals)
        return if predicate.nil? || Nodes.one_of?(predicate, LITERALS)

        shown = Nodes.compact(predicate.slice)
        literals.each do |literal|
          emit(
            :condition,
            Change.whole(predicate, literal, "replace condition `#{shown}` with #{literal}")
          )
        end
      end

      # The disabling literal repeats a deletion, or for a memo guard only skips a cache.
      def literals(node)
        disabled = visitor.walk.deleted.include?(node) || MemoGuard.match?(node)
        return %w[true false] unless Nodes.else_less?(node) && disabled

        node.is_a?(Prism::IfNode) ? %w[true] : %w[false]
      end

      # Deleting a guard's lone statement repeats a literal or the whole statement's deletion.
      def spare_guard(node)
        return unless Nodes.else_less?(node) && Nodes.single_statement(node)

        visitor.walk.spared << node.statements
      end
    end
  end
end
