# frozen_string_literal: true

module Mutato
  # Method start lines too, when coverage counts methods: an endless def gets no line hit.
  module Hits
    module_function

    def keys(path, data)
      lines = data.fetch(:lines).each_with_index.filter_map do |count, index|
        "#{path}:#{index + 1}" if count&.positive?
      end
      methods = data.fetch(:methods, {}).filter_map do |(_, _, line), count|
        "#{path}:#{line}" if count.positive?
      end
      lines + methods
    end
  end
end
