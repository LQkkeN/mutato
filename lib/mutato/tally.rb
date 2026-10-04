# frozen_string_literal: true

require "coverage"

module Mutato
  # Per test: the lines it ran, its time, whether it failed; and the files seen.
  Tally = Struct.new(:line_map, :durations, :failed, :seen, :began) do
    # Before the project loads: cached iseqs carry no coverage; lines only, for speed.
    def self.start
      ENV["DISABLE_BOOTSNAP_COMPILE_CACHE"] ||= "1"
      Coverage.start(lines: true) unless Coverage.running?
    end

    # The counters start over too: what ran before is not a test's.
    def self.fresh
      counters
      new(Hash.new { |hash, key| hash[key] = [] }, {}, [], Set.new, Clock.now)
    end

    # One read per test, as each clears the counters; its own time is not the hooks'.
    def read(prefixes)
      started = Clock.now
      hits = Tally.counters.flat_map { |path, data| keys(path, data, prefixes) }
      self.began += Clock.since(started)
      hits
    end

    # Each call clears them.
    def self.counters
      Coverage.result(stop: false, clear: true)
    end

    def keys(path, data, prefixes)
      return [] unless path.start_with?(*prefixes)

      seen << path
      Hits.keys(path, data)
    end

    # As a test runner would exit.
    def status
      failed.empty? ? 0 : 1
    end

    def finish(id, seconds, hits)
      durations[id] = seconds
      hits.each { |key| line_map[key] << id }
    end

    # Read right after the run: its time less the tests' is the hooks'. A Hash with a
    # default block cannot be marshalled.
    def to_h
      hooks = [Clock.since(began) - durations.values.sum, 0].max
      super.except(:began).merge(line_map: line_map.to_a.to_h, hooks:)
    end
  end
  public_constant :Tally
end
