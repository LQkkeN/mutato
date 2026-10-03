# frozen_string_literal: true

module Mutato
  class Annotations
    FORMATS = { "github" => :github, "plain" => :plain }.freeze
    SUMMARY = <<~MARKDOWN
      ## mutato: %<count>d survivors

      | where | mutant |
      |---|---|
      %<rows>s
    MARKDOWN
    private_constant :FORMATS, :SUMMARY

    def self.command(level, verdict, outcome)
      file, line, col, description = outcome.fetch_values(:file, :line, :col, :description)
      "::#{level} file=#{file},line=#{line},col=#{col},title=mutato::#{verdict}: #{description}"
    end

    def self.line(outcome)
      file, line, col, description = outcome.fetch_values(:file, :line, :col, :description)
      "#{file}:#{line}:#{col}: survived: #{description}"
    end

    def self.step_summary(missed)
      path = ENV.fetch("GITHUB_STEP_SUMMARY", nil)
      return unless path && missed.any?

      rows = missed.map { |outcome| row(*outcome.fetch_values(:file, :line, :description)) }
      File.write(path, format(SUMMARY, count: missed.size, rows: rows.join("\n")), mode: "a")
    end

    # GitHub splits table cells on every pipe, inside backticks too, unless escaped.
    def self.row(file, line, description)
      "| `#{file}:#{line}` | #{description.gsub("|", "\\|")} |"
    end

    def initialize(console)
      @console = console
    end

    def show(outcomes, format)
      style = FORMATS[format]
      public_send(style, outcomes) if style
    end

    def github(outcomes)
      missed = Mode.missed(outcomes)
      missed.each { |outcome| @console.out(Annotations.command("warning", "survived", outcome)) }
      notices(outcomes)
      Annotations.step_summary(missed)
    end

    def plain(outcomes)
      Mode.missed(outcomes).each { |outcome| @console.out(Annotations.line(outcome)) }
    end

    private

    def notices(outcomes)
      timeouts = outcomes.select { |outcome| outcome.fetch(:outcome) == :timeout }
      timeouts.each { |outcome| @console.out(Annotations.command("notice", "timeout", outcome)) }
    end
  end
end
