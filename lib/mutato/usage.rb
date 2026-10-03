# frozen_string_literal: true

require "prism"

module Mutato
  # Which methods are only called from logging: a file-wide fact no single method shows.
  class Usage
    def initialize(tree)
      # Names called inside logging, and names called anywhere else.
      @calls = { true => Set.new, false => Set.new }
      @private = Set.new
      scan(tree, in_arid: false)
    end

    def logging_only?(name)
      @calls.fetch(true).include?(name) && !@calls.fetch(false).include?(name)
    end

    # A private method only ever called from logging is as arid as the logging. A public one
    # may be called from another file.
    def demoted(subject)
      name = subject.name
      return subject if subject.skip || !logging_only?(name) || !@private.include?(name)

      subject.with(skip: "only used in logging")
    end

    private

    def scan(node, in_arid:)
      in_arid = called(node, in_arid:) if node.is_a?(Prism::CallNode)
      @private.merge(Privates.names(node)) if node.is_a?(Prism::StatementsNode)
      node.compact_child_nodes.each { |child| scan(child, in_arid:) }
    end

    def called(call, in_arid:)
      @calls.fetch(in_arid) << call.name
      in_arid || Arid.arid_node?(call)
    end
  end
end
