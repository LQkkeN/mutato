# frozen_string_literal: true

module Mutato
  # `shown` is where the mutant is reported; offset and bytes are what it replaces.
  Change = Data.define(:genre, :node, :shown, :offset, :bytes, :replacement, :description) do
    def self.whole(node, replacement, description)
      location = node.location
      new(
        genre: nil,
        node:,
        shown: location,
        offset: location.start_offset,
        bytes: location.length,
        replacement:,
        description:
      )
    end

    def at(location)
      with(shown: location, offset: location.start_offset, bytes: location.length)
    end

    def covering(extent)
      offset, bytes = extent
      with(offset:, bytes:)
    end

    def original(source)
      source.byteslice(offset, bytes)
    end

    # Coverage marks a statement's first line only: continuation lines go by their statement.
    def where(cursor)
      span = (cursor.statement || node).location
      {
        line: shown.start_line,
        col: shown.start_column + 1,
        start_line: span.start_line,
        end_line: span.end_line,
        outer_lines: cursor.outer_lines(node)
      }
    end

    def what(source)
      { genre:, offset:, bytes:, original: original(source), replacement:, description: }
    end
  end
  public_constant :Change
end
