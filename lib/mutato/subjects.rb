# frozen_string_literal: true

require "prism"
require_relative "subjects/scope"

module Mutato
  class Subjects
    KINDS = { Prism::ModuleNode => :module, Prism::ClassNode => :class }.freeze
    DEFINERS = {
      %w[Data define] => :class,
      %w[Struct new] => :class,
      %w[Class new] => :class,
      %w[Module new] => :module
    }.freeze
    private_constant :KINDS, :DEFINERS

    # `Point = Struct.new(:x) do ... end`: the block is the body of the class the constant names.
    def self.constant_body(node)
      call = node.value if node.is_a?(Prism::ConstantWriteNode)
      block = call.block if call.is_a?(Prism::CallNode)
      return unless block.is_a?(Prism::BlockNode)

      kind = DEFINERS[[call.receiver&.slice, call.name.to_s]]
      [kind, node.name.to_s, block.body] if kind
    end

    def self.find(file, tree)
      finder = new(file)
      finder.walk(tree, Scope.top)
      finder.found
    end

    attr_reader :found

    def initialize(file)
      @file = file
      @found = []
    end

    def walk(node, scope)
      return @found << define(node, scope) if node.is_a?(Prism::DefNode)

      kind, name, body = Subjects.constant_body(node)
      return walk(body, scope.nest(kind, name)) if body

      node.compact_child_nodes.each { |child| walk(child, scope.into(node)) }
    end

    private

    # `def More.x` inside `class More` is `def self.x`.
    def define(node, scope)
      receiver = Nodes.constant_receiver(node)
      subject = Subject.new(
        file: @file,
        name: node.name,
        chain: scope.chain,
        node:,
        receiver: (receiver unless scope.enclosing?(receiver)),
        singleton: scope.singleton_class? || Nodes.singleton_receiver?(node),
        skip: nil,
        block_lines: []
      )
      subject.with(skip: Skips.reason(subject, scope), block_lines: Nodes.block_lines(node))
    end
  end
end
