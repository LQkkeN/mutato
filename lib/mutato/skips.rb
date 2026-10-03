# frozen_string_literal: true

require "prism"

module Mutato
  module Skips
    ARID_DEFS = %i[to_s inspect].freeze
    STUB = /NotImplementedError|NoMethodError|abstract|overrid|subclass/i
    JUMPS = [Prism::ReturnNode, Prism::NextNode].freeze
    private_constant :ARID_DEFS, :STUB, :JUMPS

    module_function

    def reason(subject, scope)
      node = subject.node
      return "explicit receiver" if Nodes.foreign_receiver?(node) || scope.foreign
      return "defined inside a block" if scope.in_block
      return "arid method name" if !subject.singleton && ARID_DEFS.include?(subject.name)

      helper_reason(node) || Mutato.config.skip_reason(subject.qualified)
    end

    def helper_reason(node)
      return "logging helper" if Arid.helper_name?(node.name)

      statements = Nodes.statements_of(node.body)
      body_reason(statements) if statements
    end

    def body_reason(statements)
      return "template stub" if (statements in [only]) && stub?(only)

      "logging only" if logging_only?(statements)
    end

    # `return unless x` in a method that otherwise only logs decides whether to log.
    def logging_only?(statements)
      arid = statements.map { |statement| Arid.arid_node?(statement) }
      arid.any? && statements.zip(arid).all? { |statement, logs| logs || guard?(statement) }
    end

    def stub?(statement)
      statement.is_a?(Prism::CallNode) && statement.name == :raise && statement.slice.match?(STUB)
    end

    def guard?(statement)
      conditional = Nodes.one_of?(statement, Nodes::CONDITIONALS)
      return false unless conditional && Nodes.else_less?(statement)

      only = Nodes.single_statement(statement)
      Nodes.one_of?(only, JUMPS) && only.arguments.nil?
    end
  end
end
