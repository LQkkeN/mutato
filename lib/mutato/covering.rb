# frozen_string_literal: true

module Mutato
  class Covering
    def initialize(mutation, baseline)
      @mutation = mutation
      @baseline = baseline
      @path = File.expand_path(mutation.file)
    end

    def ids
      ids = stored? ? [] : @baseline.covering(@path, lines)
      @baseline.prioritize(ids, @mutation.file)
    end

    def absence
      return :unloaded unless @baseline.loaded?(@path)
      # An endless def gets no line event when called.
      return :uncovered if @mutation.subject.node.equal_loc

      if @baseline.booted?(@path, stored? ? holding : lines)
        :"load-time"
      else
        :uncovered
      end
    end

    private

    # Blocks run later than their method: outside one, skip its lines; inside, use its statement.
    def lines
      span = @mutation.span.to_a
      @mutation.outer_lines ? span : span - @mutation.subject.block_lines
    end

    # All its lines outside blocks: a multi-line literal's line event is on its first element.
    def holding
      @mutation.outer_lines.to_a - @mutation.subject.block_lines
    end

    def stored?
      @mutation.outer_lines && @baseline.covering(@path, holding).empty?
    end
  end
end
