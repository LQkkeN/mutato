# frozen_string_literal: true

module Mutato
  module MinitestAdapter
    # The test files: a glob's or a path's, each directory's test and spec files in order.
    module Files
      PATTERNS = ["**/*_test.rb", "**/test_*.rb", "**/*_spec.rb", "**/spec_*.rb"].freeze
      # System tests, an embedded app's tests and fixtures: left out unless named themselves.
      APART = %w[system/ dummy/ fixtures/].freeze
      private_constant :PATTERNS, :APART

      module_function

      def find(args)
        args.flat_map { |arg| matches(arg) }
          .uniq
      end

      def matches(arg)
        found = Dir.glob(arg).sort
        raise Abort.new("no test files at #{arg}", code: 1) if found.empty?

        found.flat_map { |path| File.directory?(path) ? in_directory(path) : [path] }
      end

      def in_directory(directory)
        files = Dir.glob(PATTERNS, base: directory).reject { |file| file.start_with?(*APART) }
        files.sort.map { |file| File.join(directory, file) }
      end

      # Where the test paths' helpers live, besides lib and test.
      def load_path(args)
        (%w[lib test] + tops(args)).uniq.map { |dir| File.expand_path(dir) }
      end

      def tops(args)
        matches = args.flat_map { |arg| Dir.glob(arg) }
        matches.map { |path| top(File.expand_path(path)) }
      end

      # Below the current directory, the first directory on the way; elsewhere, its own.
      def top(full)
        directory = File.directory?(full) ? full : File.dirname(full)
        inside = directory.delete_prefix("#{Dir.pwd}/")
        inside == directory ? directory : inside.split("/").first
      end
    end
    public_constant :Files
  end
end
