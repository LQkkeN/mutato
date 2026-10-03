# frozen_string_literal: true

require "prism"

module Mutato
  module Nodes
    BLOCKS = [Prism::BlockNode, Prism::LambdaNode].freeze
    CONDITIONALS = [Prism::IfNode, Prism::UnlessNode].freeze
    HEREDOC_CAPABLE = [
      Prism::StringNode,
      Prism::InterpolatedStringNode,
      Prism::XStringNode,
      Prism::InterpolatedXStringNode
    ].freeze
    LITERALS = [
      Prism::StringNode,
      Prism::SymbolNode,
      Prism::IntegerNode,
      Prism::FloatNode,
      Prism::NilNode,
      Prism::TrueNode,
      Prism::FalseNode
    ].freeze
    MEMO_GUARD = /\Areturn (@\w+) if \1\z/
    public_constant :BLOCKS, :CONDITIONALS, :LITERALS
    private_constant :HEREDOC_CAPABLE, :MEMO_GUARD

    module_function

    # Named, not anonymous: Ruby 3.3.0 rejects `&` forwarded from inside a block.
    def each_node(node, &block)
      return enum_for(:each_node, node) unless block

      yield(node)
      node.compact_child_nodes.each { |child| each_node(child, &block) }
    end

    def using?(node)
      node.is_a?(Prism::CallNode) && node.name == :using && node.receiver.nil?
    end

    def one_of?(node, classes)
      classes.any? { |klass| node.is_a?(klass) }
    end

    # The statements of a def body, looking through the begin a rescue adds.
    def statements_of(body)
      body = body.statements if body.is_a?(Prism::BeginNode)
      body.body if body.is_a?(Prism::StatementsNode)
    end

    def else_less?(node)
      node.is_a?(Prism::IfNode) ? node.subsequent.nil? : node.else_clause.nil?
    end

    def constant_receiver(definition)
      receiver = definition.receiver
      receiver.slice if receiver.is_a?(Prism::ConstantReadNode)
    end

    def singleton_receiver?(definition)
      receiver = definition.receiver
      receiver.is_a?(Prism::SelfNode) || receiver.is_a?(Prism::ConstantReadNode)
    end

    def foreign_receiver?(definition)
      receiver = definition.receiver
      receiver && !singleton_receiver?(definition)
    end

    # Lines inside blocks may run later than the method itself (define_method, Thread.new).
    def block_lines(definition)
      blocks = each_node(definition).select { |inner| one_of?(inner, BLOCKS) }
      blocks.flat_map do |block|
        location = block.location
        ((location.start_line + 1)..location.end_line).to_a
      end
    end

    # `x.size > 0`: a comparison a count can never fail.
    def count_against_zero?(call)
      receiver = call.receiver
      argument = sole_argument(call)
      receiver.is_a?(Prism::CallNode) && %i[length size count].include?(receiver.name) &&
        argument.is_a?(Prism::IntegerNode) && argument.value.zero?
    end

    # `initialize` and setters: their caller never sees the value they return.
    def value_dropped?(name)
      name == :initialize || name.to_s.match?(/\A\w+=\z/)
    end

    # `return @x if @x`: deleting it, or making it never return, only skips a cache.
    def memo_guard?(statement)
      statement.slice.match?(MEMO_GUARD)
    end

    def nil_store?(call)
      call.name == :[]= && arguments_of(call).last.is_a?(Prism::NilNode)
    end

    def nil_valued?(element)
      value = element.is_a?(Prism::AssocNode) ? element.value : element
      value.is_a?(Prism::NilNode) || value.is_a?(Prism::FalseNode)
    end

    def single_statement(conditional)
      return unless conditional.statements&.body in [only]

      only
    end

    def arguments_of(call)
      call.arguments&.arguments || []
    end

    def sole_argument(call)
      argument, = arguments_of(call)
      argument
    end

    # `a + b`, `x < 1`: one receiver, one argument, no parentheses, the name spelled out.
    def binary_operator?(call)
      message = call.message_loc
      call.receiver && message && call.opening_loc.nil? &&
        arguments_of(call).size == 1 && message.slice == call.name.to_s
    end

    # A heredoc's body lies below its statement and goes with it; the terminator's newline stays.
    def extent(node, source)
      location = node.location
      start = location.start_offset
      stop = [location.end_offset, *heredoc_ends(node)].max
      stop -= 1 if source.getbyte(stop - 1) == "\n".ord
      [start, stop - start]
    end

    def heredoc_ends(node)
      heredocs = each_node(node).select do |inner|
        one_of?(inner, HEREDOC_CAPABLE) && inner.heredoc?
      end
      heredocs.map { |heredoc| heredoc.closing_loc.end_offset }
    end

    def compact(text)
      joined = text.gsub(/\s*\\\n\s*/, " ").gsub(/\s+/, " ")
      joined.sub(/\A(.{57}).{4,}\z/, "\\1...")
    end
  end
end
