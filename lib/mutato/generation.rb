# frozen_string_literal: true

require "prism"

module Mutato
  class Generation
    def initialize(file, source)
      @file = file
      @source = source
      @tree = Prism.parse(source).value
      @emitter = Emitter.new(file, source)
    end

    def generator
      subjects = found
      kept, dropped = mutate(subjects).partition { |mutation| parses?(mutation) }
      Generator.new(file: @file, source: @source, subjects:, mutations: kept, dropped:)
    end

    private

    def found
      usage = Usage.new(@tree)
      Subjects.find(@file, @tree).map { |subject| usage.demoted(subject) }
    end

    def mutate(subjects)
      subjects.reject(&:skip).each { |subject| Visitor.new(subject, @emitter).run }
      @emitter.mutations
    end

    def parses?(mutation)
      Prism.parse(mutation.mutated_source(@source)).errors.empty?
    end
  end
end
