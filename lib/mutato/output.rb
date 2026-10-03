# frozen_string_literal: true

require "fileutils"
require "json"

module Mutato
  class Output
    OUTCOMES = %w[
      caught
      missed
      timeout
      unjudged
      equivalent
      overwritten
      unviable
      crashed
      uncovered
      load-time
      unloaded
    ].freeze
    LOG_CAP = 1_000_000
    private_constant :OUTCOMES, :LOG_CAP

    # Logs hold whatever the application printed; keep the last megabyte.
    def self.cap(log)
      size = File.size?(log)
      return unless size && size > LOG_CAP

      File.binwrite(log, "mutato: log truncated to its last #{LOG_CAP} bytes\n#{tail(log)}")
    end

    # Only the tail is read: a runaway mutant's log can be gigabytes.
    def self.tail(log)
      File.open(log, "rb") do |file|
        file.seek(-LOG_CAP, IO::SEEK_END)
        file.read
      end
    end

    def self.listed(outcomes, name)
      chosen = outcomes.select { |outcome| outcome.fetch(:outcome).to_s == name }
      chosen.map { |outcome| "#{outcome.fetch(:id)}  #{outcome.fetch(:label)}" }
    end

    # A run starts outcomes.jsonl afresh, as it rewrites the other lists.
    def initialize(dir)
      @dir = dir
      FileUtils.mkdir_p(File.join(dir, "logs"))
      File.write(File.join(dir, "outcomes.jsonl"), "")
    end

    def log_path(id)
      File.join(@dir, "logs", "#{id}.log")
    end

    def append(outcome)
      File.write(File.join(@dir, "outcomes.jsonl"), "#{JSON.generate(outcome)}\n", mode: "a")
    end

    def write(outcomes, flaky)
      File.write(File.join(@dir, "outcomes.json"), JSON.pretty_generate(outcomes))
      OUTCOMES.each { |name| write_list("#{name}.txt", Output.listed(outcomes, name)) }
      write_list("flaky.txt", flaky)
    end

    private

    def write_list(name, lines)
      File.write(
        File.join(@dir, name),
        lines.map { |line| "#{line}\n" }
        .join
      )
    end
  end
end
