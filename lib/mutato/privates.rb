# frozen_string_literal: true

require "prism"

module Mutato
  # The private method names of one statement list: `private def x`, `private :x`, and the
  # defs after a bare `private`, until `public` or `protected`.
  module Privates
    VISIBILITY = %i[private public protected].freeze
    private_constant :VISIBILITY

    module_function

    def names(statements)
      hidden = false
      statements.body.each_with_object([]) do |statement, names|
        hidden = section(statement, hidden)
        names.concat(listed(statement))
        names << statement.name if hidden && statement.is_a?(Prism::DefNode)
      end
    end

    def section(statement, hidden)
      return hidden unless visibility?(statement) && Nodes.arguments_of(statement).empty?

      statement.name == :private
    end

    def listed(statement)
      return [] unless visibility?(statement) && statement.name == :private

      Nodes.arguments_of(statement).filter_map { |argument| Privates.name_of(argument) }
    end

    def name_of(argument)
      return argument.name if argument.is_a?(Prism::DefNode)

      argument.unescaped.to_sym if Nodes.one_of?(argument, [Prism::SymbolNode, Prism::StringNode])
    end

    def visibility?(statement)
      statement.is_a?(Prism::CallNode) && statement.receiver.nil? &&
        VISIBILITY.include?(statement.name)
    end
  end
end
