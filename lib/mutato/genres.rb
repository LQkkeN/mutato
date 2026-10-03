# frozen_string_literal: true

require "prism"
require_relative "genres/conditions"
require_relative "genres/elements"
require_relative "genres/operators"
require_relative "genres/statements"
require_relative "genres/swaps"
require_relative "genres/values"

module Mutato
  module Genres
    COLLECTIONS = [Prism::ArrayNode, Prism::HashNode, Prism::KeywordHashNode].freeze
    COMPOUNDS = [
      Prism::LocalVariableOperatorWriteNode,
      Prism::InstanceVariableOperatorWriteNode,
      Prism::ClassVariableOperatorWriteNode,
      Prism::GlobalVariableOperatorWriteNode,
      Prism::IndexOperatorWriteNode,
      Prism::CallOperatorWriteNode,
      Prism::ConstantOperatorWriteNode,
      Prism::ConstantPathOperatorWriteNode
    ].freeze
    private_constant :COLLECTIONS, :COMPOUNDS

    module_function

    # :stop leaves the node's children alone.
    def mutate(visitor, node)
      case node
      when Prism::IfNode, Prism::UnlessNode then Conditions.new(visitor).branch(node)
      when Prism::WhileNode, Prism::UntilNode then Conditions.new(visitor).loop(node)
      when Prism::AndNode, Prism::OrNode then Conditions.new(visitor).connector(node)
      when Prism::CallNode then call(visitor, node)
      else other(visitor, node)
      end
    end

    def other(visitor, node)
      return Elements.new(visitor).mutate(node) if Nodes.one_of?(node, COLLECTIONS)

      Operators.new(visitor).compound(node) if Nodes.one_of?(node, COMPOUNDS)
    end

    # Nothing inside a logger call, or a loop that only logs, is mutated either.
    def call(visitor, call)
      return :stop if Arid.arid_node?(call)

      Operators.new(visitor).mutate(call) if Nodes.binary_operator?(call)
      Swaps.new(visitor).mutate(call)
    end
  end
end
