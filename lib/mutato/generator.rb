# frozen_string_literal: true

module Mutato
  Generator = Data.define(:file, :source, :subjects, :mutations, :dropped) do
    def self.read(file)
      Generation.new(file, File.read(file)).generator
    end
  end
  public_constant :Generator
end
