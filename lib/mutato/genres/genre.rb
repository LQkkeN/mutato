# frozen_string_literal: true

module Mutato
  module Genres
    class Genre
      def initialize(visitor)
        @visitor = visitor
      end

      private

      attr_reader :visitor

      def emit(genre, change)
        visitor.emit(genre, change)
      end

      def source
        visitor.source
      end
    end
  end
end
