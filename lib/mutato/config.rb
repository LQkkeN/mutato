# frozen_string_literal: true

module Mutato
  class Config
    Skip = Data.define(:pattern, :reason)
    private_constant :Skip

    attr_reader :hooks

    def initialize
      @hooks = Hash.new { |hash, name| hash[name] = [] }
      @skips = []
      @arid = Set.new
    end

    def run_hooks(name)
      @hooks.fetch(name, []).each(&:call)
    end

    # A String names one method exactly; a Regexp matches the qualified name.
    def skip(pattern, reason)
      pattern = /\A#{Regexp.escape(pattern)}\z/ if pattern.is_a?(String)
      @skips << Skip.new(pattern:, reason:)
    end

    def skip_reason(qualified)
      @skips.find { |skip| skip.pattern.match?(qualified) }
        &.reason
    end

    def arid(*names)
      @arid.merge(names.map(&:to_s))
    end

    def arid?(name)
      @arid.include?(name.to_s)
    end
  end
end
