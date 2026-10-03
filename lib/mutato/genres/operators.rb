# frozen_string_literal: true

require "prism"
require_relative "genre"

module Mutato
  module Genres
    class Operators < Genre
      RELATIONAL = {
        "<" => %w[<= !=],
        "<=" => %w[< ==],
        ">" => %w[>= !=],
        ">=" => %w[> ==],
        "==" => %w[!=],
        "!=" => %w[==]
      }.freeze
      # What a comparison gives when both sides are equal.
      ALWAYS = { "<" => "false", "<=" => "true", ">" => "false", ">=" => "true" }.freeze
      ARITHMETIC = { "+" => "-", "-" => "+", "*" => "/", "/" => "*" }.freeze
      NON_COMMUTATIVE = %w[- / % **].freeze
      private_constant :RELATIONAL, :ALWAYS, :ARITHMETIC, :NON_COMMUTATIVE

      # A length is never negative, so `size > 0` is `size != 0`.
      def self.neighbours(call, name)
        same = name == ">" && Nodes.count_against_zero?(call)
        RELATIONAL.fetch(name).reject { |operator| same && operator == "!=" }
      end

      def mutate(call)
        name = call.name.to_s
        relational(call, name) if RELATIONAL.key?(name)
        arithmetic = ARITHMETIC[name]
        operator(call, arithmetic, :arithmetic) if arithmetic
        swap_operands(call) if NON_COMMUTATIVE.include?(name)
      end

      def compound(node)
        operator = node.binary_operator.to_s
        replacement = ARITHMETIC[operator]
        return unless replacement

        change = Change.whole(
          node,
          "#{replacement}=",
          "replace `#{operator}=` with `#{replacement}=`"
        )
        emit(:arithmetic, change.at(node.binary_operator_loc))
      end

      private

      def relational(call, name)
        Operators.neighbours(call, name).each { |operator| operator(call, operator, :relational) }
        literal = ALWAYS[name]
        always(call, literal) if literal
      end

      def operator(call, replacement, genre)
        change = Change.whole(call, replacement, "replace `#{call.name}` with `#{replacement}`")
        emit(genre, change.at(call.message_loc))
      end

      def always(call, literal)
        emit(
          :relational,
          Change.whole(call, literal, "replace `#{Nodes.compact(call.slice)}` with #{literal}")
        )
      end

      def swap_operands(call)
        name = call.name
        lhs = call.receiver.slice
        rhs = Nodes.sole_argument(call).slice
        emit(
          :arithmetic,
          Change.whole(call, "(#{rhs}) #{name} (#{lhs})", "swap operands of `#{name}`")
        )
      end
    end
  end
end
