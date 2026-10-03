# frozen_string_literal: true

require "prism"
require_relative "genre"

module Mutato
  module Genres
    class Values < Genre
      GUESSES = {
        Prism::ArrayNode => "[]",
        Prism::HashNode => "{}",
        Prism::StringNode => '""',
        Prism::InterpolatedStringNode => '""',
        Prism::IntegerNode => "0",
        Prism::TrueNode => "true",
        Prism::FalseNode => "true"
      }.freeze
      private_constant :GUESSES

      def mutate(body)
        # A def with a rescue: the statements are what the method returns.
        body = body.statements if body.is_a?(Prism::BeginNode)
        return unless body.is_a?(Prism::StatementsNode)

        guesses(body.body.last).each do |value|
          description = "replace body of #{visitor.subject} with #{value}"
          emit(:value, Change.whole(body, value, description).covering(Nodes.extent(body, source)))
        end
      end

      private

      def guesses(last)
        return %w[true false] if visitor.subject.name.to_s.end_with?("?")

        guessed = GUESSES.filter_map { |klass, value| value if last.is_a?(klass) }
        ["nil", *guessed].uniq
      end
    end
  end
end
