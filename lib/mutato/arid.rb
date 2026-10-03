# frozen_string_literal: true

require "prism"

module Mutato
  # Code no test asserts on (output, logging): mutating it only makes survivors.
  module Arid
    METHODS = %i[puts warn p pp print require require_relative].freeze
    LOGGING = /\Alog(?:ger)?\z/i
    # `log_error(e)`, `logger_info`: a level after the underscore, so `log_in` is not one.
    HELPER = /\Alog(?:ger)?(?:_(?:debug|info|warn|warning|error|fatal|exception|event|message))?\z/i
    VARIABLES = [
      Prism::InstanceVariableReadNode,
      Prism::ClassVariableReadNode,
      Prism::GlobalVariableReadNode,
      Prism::LocalVariableReadNode
    ].freeze
    ITERATORS = %i[
      each
      each_with_index
      each_with_object
      each_pair
      each_key
      each_value
      reverse_each
      times
      upto
      downto
      step
    ].freeze
    private_constant :METHODS, :LOGGING, :HELPER, :VARIABLES, :ITERATORS

    module_function

    def helper_name?(name)
      name.to_s.match?(HELPER)
    end

    # A compound of arid parts is arid, and so is one with none: `if x; end`.
    def arid_node?(node)
      case node
      when Prism::CallNode then arid_with_block?(node) || arid_loop?(node)
      when Prism::IfNode, Prism::UnlessNode then all_arid?(branches_of(node))
      when Prism::StatementsNode, Prism::ElseNode then all_arid?(node.compact_child_nodes)
      else false
      end
    end

    def all_arid?(parts)
      parts.all? { |part| arid_node?(part) }
    end

    # A logging call with a block is arid only if its block is: `logger.tagged { work }` works.
    def arid_with_block?(call)
      block = call.block
      body = block.body if block.is_a?(Prism::BlockNode)
      arid_call?(call) && all_arid?([body].compact)
    end

    def arid_loop?(call)
      block = call.block
      ITERATORS.include?(call.name) && block.is_a?(Prism::BlockNode) && arid_node?(block.body)
    end

    def branches_of(conditional)
      conditional.compact_child_nodes - [conditional.predicate]
    end

    def arid_call?(call)
      name = call.name
      receiver = call.receiver
      return true if METHODS.include?(name) && console?(receiver)

      Mutato.config.arid?(name) || (receiver.nil? && helper_name?(name)) || logging?(receiver)
    end

    # `puts` to the console, not to an IO the code was handed.
    def console?(receiver)
      receiver.nil? || receiver.slice.match?(/\A(?:\$std(?:out|err)|STD(?:OUT|ERR))\z/)
    end

    def logging?(receiver)
      case receiver
      when Prism::CallNode then logging_call?(receiver)
      when Prism::ConstantReadNode, Prism::ConstantPathNode then logging_constant?(receiver.slice)
      when *VARIABLES then receiver.name.to_s.sub(/\A(?:@@?|\$)/, "").match?(LOGGING)
      else false
      end
    end

    # `App.logger`, a reader without arguments (not `Math.log(x)`), or `opts[:logger]`.
    def logging_call?(call)
      arguments = Nodes.arguments_of(call)
      name = call.name
      return name.to_s.match?(LOGGING) && arguments.empty? unless name == :[]

      (arguments in [key]) && key.slice.match?(/\A[:"']?log(?:ger)?["']?\z/i)
    end

    def logging_constant?(name)
      name.split("::").last.match?(LOGGING) || Mutato.config.arid?(name)
    end
  end
end
