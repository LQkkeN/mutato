# frozen_string_literal: true

require "digest"

module Mutato
  class Emitter
    attr_reader :source, :mutations

    def initialize(file, source)
      @file = file
      @source = source
      @seen = Set.new
      @mutations = []
    end

    def add(change, subject, cursor)
      replacement = change.replacement
      return if change.original(@source) == replacement
      return unless @seen.add?([change.offset, change.bytes, replacement])

      @mutations << Mutation.new(
        id: id_for(change, subject),
        file: @file,
        subject:,
        **change.where(cursor),
        **change.what(@source)
      )
    end

    private

    # The offset within the def: distinct for two `+` on a line, stable when other code moves.
    def id_for(change, subject)
      within = change.offset - subject.node.location.start_offset
      parts = [
        @file,
        subject.qualified,
        change.genre,
        within,
        change.original(@source),
        change.replacement
      ]
      Digest::SHA1.hexdigest(parts.join("\0"))[0, 12]
    end
  end
end
