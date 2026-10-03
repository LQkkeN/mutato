# frozen_string_literal: true

require "prism"
require_relative "genre"

module Mutato
  module Genres
    class Swaps < Genre
      SWAPS = {
        max: %i[min],
        min: %i[max],
        first: %i[last],
        last: %i[first],
        round: %i[floor ceil],
        floor: %i[round ceil],
        ceil: %i[round floor],
        truncate: %i[round],
        any?: %i[all? none?],
        all?: %i[any?],
        none?: %i[any?],
        empty?: %i[any?]
      }.freeze
      FINDERS = %i[first last].freeze
      private_constant :SWAPS, :FINDERS

      # `first(id: x)` is a finder, and a receiverless `max` the method's own: not Array calls.
      def self.swappable?(call)
        return false if call.receiver.nil?

        !(FINDERS.include?(call.name) && (call.arguments || call.block))
      end

      def mutate(call)
        name = call.name
        negation(call) if name == :! && call.receiver
        replacements = SWAPS[name]
        methods(call, replacements) if replacements && Swaps.swappable?(call)
      end

      private

      def negation(call)
        emit(
          :condition,
          Change.whole(call, call.receiver.slice, "drop `!` from `#{Nodes.compact(call.slice)}`")
        )
      end

      def methods(call, replacements)
        name = call.name
        replacements.each do |replacement|
          change = Change.whole(call, replacement.to_s, "replace `.#{name}` with `.#{replacement}`")
          emit(:"swap-method", change.at(call.message_loc))
        end
      end
    end
  end
end
