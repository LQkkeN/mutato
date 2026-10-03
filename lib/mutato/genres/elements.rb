# frozen_string_literal: true

require "prism"
require_relative "genre"

module Mutato
  module Genres
    # Newlines stay with a dropped element, so line numbers hold.
    class Elements < Genre
      MAX = 10
      private_constant :MAX

      # A lone element has nothing to drop it from; only its trailing comma would go.
      def mutate(node)
        elements = node.elements
        return unless (2..MAX).cover?(elements.size)

        elements.each_index do |index|
          drop(elements, index) unless Nodes.nil_valued?(elements[index])
        end
      end

      private

      def drop(elements, index)
        from, to = range(elements, index)
        element = elements[index]
        newlines = "\n" * source.byteslice(from...to).count("\n")
        change = Change.whole(element, newlines, "drop `#{Nodes.compact(element.slice)}`")
        emit(:element, change.covering([from, to - from]))
      end

      # The last element goes from the previous one's end, trailing comma included.
      def range(elements, index)
        location = elements[index].location
        following = elements[index + 1]
        return [location.start_offset, following.location.start_offset] if following

        stop = location.end_offset
        [elements[index - 1].location.end_offset, stop + trailing_comma(stop).bytesize]
      end

      # Only a comma that ends the list: one before `&block` must stay.
      def trailing_comma(offset)
        source.byteslice(offset, 200).to_s.b[/\A\s*,(?=(?:\s|#[^\n]*)*[\]})])/].to_s
      end
    end
  end
end
