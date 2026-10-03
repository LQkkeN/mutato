# frozen_string_literal: true

module Mutato
  class Diff
    def self.read(option)
      new(option == "-" ? $stdin.read : File.read(option))
    end

    # `+++ b/lib/a.rb`, maybe a tab and timestamp after (diff -u, hg); c/ i/ o/ w/ from git.
    def self.path(row)
      row.delete_prefix("+++ ").partition("\t").first.strip.sub(%r{\A[abciow]/}, "")
    end

    def initialize(text)
      @lines = Hash.new { |hash, file| hash[file] = [] }
      @file = nil
      @line = 0
      # Only the paths matter; a stray byte elsewhere must not stop the reading.
      text.dup.force_encoding(Encoding::UTF_8).scrub.each_line { |row| take(row) }
    end

    # Both paths from the current directory: `lib`, `./lib` and an absolute path agree.
    def touches?(file, range)
      @lines.fetch(File.expand_path(file), []).any? { |line| range.cover?(line) }
    end

    private

    def take(row)
      if row.start_with?("+++ ") then @file = File.expand_path(Diff.path(row))
      elsif (hunk = row.match(/\A@@ -\d+(?:,\d+)? \+(\d+)/)) then @line = Integer(hunk[1], 10)
      elsif row.start_with?("+") then added
      elsif row.start_with?(" ") then @line += 1
      end
    end

    def added
      @lines[@file] << @line
      @line += 1
    end
  end
end
