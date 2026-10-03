# frozen_string_literal: true

require "prism"
require_relative "visitor/cursor"
require_relative "visitor/walk"

module Mutato
  class Visitor
    DEFINITIONS = [Prism::DefNode, Prism::ClassNode, Prism::ModuleNode].freeze
    private_constant :DEFINITIONS

    attr_reader :subject, :walk

    def initialize(subject, emitter)
      @subject = subject
      @emitter = emitter
      @walk = Walk.start
    end

    # The last statement is the value and stays, unless the caller drops it: `new`, `x.y = 1`.
    def run
      body = subject.node.body
      Genres::Values.new(self).mutate(body)
      statements = Nodes.statements_of(body)
      walk.spared << statements.last if statements && !Nodes.value_dropped?(subject.name)
      visit(body)
    end

    def source
      @emitter.source
    end

    def emit(genre, change)
      @emitter.add(change.with(genre:), subject, walk.cursor)
    end

    def with_statement(statement, &)
      with_cursor(walk.cursor.at(statement), &)
    end

    def visit(node)
      case node
      when Prism::StatementsNode then visit_statements(node)
      when Prism::BlockNode, Prism::LambdaNode then visit_block(node)
      when Prism::EmbeddedStatementsNode, Prism::ParenthesesNode then visit_expression(node)
      when nil, *DEFINITIONS then nil
      else visit_other(node)
      end
    end

    private

    def visit_statements(node)
      Genres::Statements.new(self).mutate(node)
      node.body.each { |statement| visit_statement(statement) }
    end

    # Nothing inside a store no one reads is mutated either.
    def visit_statement(statement)
      with_statement(statement) { visit(statement) } unless walk.dead.include?(statement)
    end

    def visit_block(node)
      with_cursor(walk.cursor.inside_block) { visit_children(node) }
    end

    # Statements inside `#{}` or parentheses are expressions: mutated, never deleted.
    def visit_expression(node)
      node.compact_child_nodes.flat_map(&:body).each { |child| visit(child) }
    end

    def visit_other(node)
      visit_children(node) unless Genres.mutate(self, node) == :stop
    end

    def visit_children(node)
      node.compact_child_nodes.each { |child| visit(child) }
    end

    def with_cursor(cursor)
      previous = walk.cursor
      walk.cursor = cursor
      yield
    ensure
      walk.cursor = previous
    end
  end
end
