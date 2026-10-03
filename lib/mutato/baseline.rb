# frozen_string_literal: true

module Mutato
  # hooks: the seconds the suite and group hooks took, which every run repeats.
  Baseline = Data.define(
    :line_map,
    :durations,
    :order,
    :hooks,
    :locations,
    :boot_lines,
    :loaded_files
  ) do
    # `lib/calc/helpers.rb` is tested by `helpers_spec.rb` or `calc_helpers_spec.rb`.
    def self.stems_of(file)
      stems = [File.basename(file, ".rb"), file.delete_suffix(".rb").split("/").drop(1).join("_")]
      stems.reject(&:empty?)
    end

    def covering(path, lines)
      ids = lines.flat_map { |line| line_map.fetch("#{path}:#{line}", []) }
      ids.uniq
    end

    def budget(ids, minimum)
      [minimum, ids.sum { |id| durations.fetch(id) } * 5].max + hooks
    end

    def loaded?(path)
      loaded_files.include?(path)
    end

    def booted?(path, lines)
      lines.any? { |line| boot_lines.include?("#{path}:#{line}") }
    end

    # Named tests kill soonest; baseline order keeps order-dependent suites working.
    def prioritize(ids, file)
      stems = Baseline.stems_of(file)
      ids.sort_by { |id| [named_after?(id, stems) ? 0 : 1, order.fetch(id, Float::INFINITY)] }
    end

    private

    def named_after?(id, stems)
      base = File.basename(locations.fetch(id))
      stems.any? { |stem| base.start_with?("#{stem}_", "test_#{stem}") }
    end
  end
  public_constant :Baseline
end
