# frozen_string_literal: true

module Mutato
  class Selection
    attr_reader :paths, :options

    def self.by_id(todo, ids)
      index = todo.to_h { |mutation| [mutation.id, mutation] }
      ids.map { |id| index.fetch(id) }
    end

    # Under the current directory, the first directory of the path; elsewhere, the path itself.
    def self.root_of(path)
      here = Dir.pwd
      inside = path.delete_prefix("#{here}/")
      inside == path ? path : File.join(here, inside.split("/").first)
    end

    def initialize(paths, options)
      @paths = paths
      @options = options
      @generators = nil
      @diff = nil
    end

    def files
      @paths.flat_map { |path| File.directory?(path) ? Dir["#{path}/**/*.rb"].sort : [path] }
    end

    def generators
      @generators ||= files.map { |file| Generator.read(file) }
    end

    def subjects
      generators.flat_map(&:subjects)
    end

    def mutations
      limit = @options.limit
      limit ? narrowed.first(limit) : narrowed
    end

    def controls
      subjects.reject(&:skip).map { |subject| Mutation.control(subject) }
    end

    def unknown(todo)
      @options.only.to_a - todo.map(&:id)
    end

    # The same random subset every run.
    def chosen(todo)
      only = @options.only
      sample = @options.sample
      todo = Selection.by_id(todo, only) if only
      sample ? todo.sample(sample, random: Random.new(1)) : todo
    end

    def prefixes
      roots = @paths.map { |path| Selection.root_of(File.expand_path(path)) }
      roots.uniq
    end

    def summary(todo)
      skipped, kept = subjects.partition(&:skip)
      [
        "#{todo.size} mutants over #{files.size} files, #{kept.size} methods",
        *without_methods,
        *dropped,
        *skipped.map(&:skipped_line)
      ]
    end

    private

    def narrowed
      all = generators.flat_map(&:mutations).select { |mutation| @options.genre?(mutation.genre) }
      @options.diff ? all.select { |mutation| diff.touches?(mutation.file, mutation.span) } : all
    end

    def diff
      @diff ||= Diff.read(@options.diff)
    end

    def without_methods
      empty = generators.select { |generator| generator.subjects.empty? }
      return if empty.none?

      ["#{empty.size} files without methods (code in blocks or at class level is not mutated)"]
    end

    def dropped
      dropped = generators.flat_map(&:dropped)
      return if dropped.empty?

      examples = dropped.first(3).map(&:label).join("; ")
      ["#{dropped.size} mutants dropped as unparsable, e.g. #{examples}"]
    end
  end
end
