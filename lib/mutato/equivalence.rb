# frozen_string_literal: true

module Mutato
  module Equivalence
    # BasicObject's is empty; Struct's, given nothing, sets members to the nil they hold.
    EMPTY = [BasicObject.instance_method(:initialize), Struct.instance_method(:initialize)].freeze
    private_constant :EMPTY

    module_function

    # In a module, where `super` goes depends on the class that includes it.
    def equivalent?(mutation)
      subject = mutation.subject
      empty_super?(mutation) && loaded?(subject) &&
        EMPTY.include?(Installer.current(subject)&.super_method)
    end

    # A class only the tests load is unknown here; its mutant runs, and the child loads it.
    def loaded?(subject)
      name = subject.owner_name
      name.empty? || Object.const_defined?(name)
    end

    # A bare `super` with parameters passes them on.
    def empty_super?(mutation)
      text = mutation.original
      text == "super()" || (text == "super" && mutation.subject.node.parameters.nil?)
    end
  end
end
