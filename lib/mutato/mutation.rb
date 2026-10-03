# frozen_string_literal: true

module Mutato
  Mutation = Data.define(
    :id,
    :file,
    :subject,
    :genre,
    :line,
    :col,
    :start_line,
    :end_line,
    :outer_lines,
    :offset,
    :bytes,
    :original,
    :replacement,
    :description
  ) do
    # The span starts below the def line, which runs at load; a one-liner's is empty: uncovered.
    def self.control(subject)
      location = subject.node.location
      first = location.start_line
      new(
        id: "control-#{subject.qualified.tr("/", "_")}",
        file: subject.file,
        subject:,
        genre: :control,
        line: first,
        col: 1,
        start_line: first + 1,
        end_line: location.end_line,
        outer_lines: nil,
        offset: location.start_offset,
        bytes: 0,
        original: "",
        replacement: "",
        description: "reinstall #{subject} unchanged"
      )
    end

    def label
      "#{file}:#{line}:#{col}: [#{genre}] #{description}"
    end

    alias_method :to_s, :label

    def listing
      "#{id}  #{label}  (#{subject})"
    end

    def span
      start_line..end_line
    end

    def record(ids)
      {
        id:,
        label:,
        genre:,
        file:,
        line:,
        col:,
        description:,
        examples: ids.size,
        ids:,
        seconds: 0.0
      }
    end

    def apply(source)
      mutated = source.b
      mutated[offset, bytes] = replacement.b
      mutated.force_encoding(source.encoding)
    end

    def mutated_source(file_source)
      mutated = apply(file_source)
      delta = replacement.bytesize - bytes
      location = subject.node.location
      mutated.b[location.start_offset, location.length + delta].force_encoding(file_source.encoding)
    end
  end
  public_constant :Mutation
end
