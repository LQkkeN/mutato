# frozen_string_literal: true

require_relative "installer/header"

module Mutato
  # Wrapped in the original nesting, so constant lookup in the mutant still works.
  class Installer
    class Unviable < StandardError
    end
    public_constant :Unviable

    # Whatever stops the mutated method from loading makes the mutant unviable.
    def self.install(subject, def_source)
      quietly { new(subject).install(def_source) }
    rescue ScriptError, StandardError => error
      raise Unviable, "#{error.class}: #{error.message.lines.first.to_s.strip}"
    end

    # The method as it is now, to tell if the tests replaced the installed one.
    def self.current(subject)
      new(subject).current
    end

    def self.methods_of(owner)
      owner.instance_methods(false) + owner.private_instance_methods(false)
    end

    # Redefining warns under -w, which a suite failing on warnings turns into unviable mutants.
    def self.quietly
      verbose = $VERBOSE
      $VERBOSE = nil
      yield
    ensure
      $VERBOSE = verbose
    end

    def initialize(subject)
      @subject = subject
      @name = subject.name
    end

    def install(def_source)
      owner = loaded_owner
      visibility = visibility_of(owner)
      twins = twins_of(owner)
      Header.evaluate(wrap(def_source, visibility), @subject)
      restore(owner, visibility, twins)
    end

    def current
      owner = resolve_owner
      owner.instance_method(@name) if defines?(owner)
    end

    def wrap(def_source, visibility)
      "#{openers.join(" ")}\n#{prefix(visibility)}#{def_source}\n#{" end" * @subject.chain.size}"
    end

    private

    def openers
      @subject.chain.map { |kind, name| kind == :sclass ? "class << self;" : "#{kind} #{name};" }
    end

    # `private def` keeps a method_added hook from seeing a public def.
    def prefix(visibility)
      visibility == :public || @subject.singleton ? "" : "#{visibility} "
    end

    # A class a framework loads on first use is loaded from the file.
    def loaded_owner
      name = @subject.owner_name
      require File.expand_path(@subject.file) unless name.empty? || Object.const_defined?(name)
      resolve_owner
    end

    # Aliases of the old body, and module_function's singleton copy, must follow.
    def twins_of(owner)
      return [] unless defines?(owner)

      target = owner.instance_method(@name)
      Installer.methods_of(owner).select do |name|
        name != @name && owner.instance_method(name) == target
      end
    end

    def defines?(owner)
      owner.method_defined?(@name) || owner.private_method_defined?(@name)
    end

    # The visibility methods are private, hence __send__.
    def restore(owner, visibility, twins)
      twins.each { |name| owner.alias_method(name, @name) }
      owner.__send__(:module_function, @name) if visibility == :private && module_function?(owner)
      owner.__send__(visibility, @name) if @subject.singleton && visibility != :public
      owner.instance_method(@name)
    end

    def module_function?(owner)
      owner.instance_of?(Module) && owner.singleton_methods(false).include?(@name)
    end

    def resolve_owner
      receiver = @subject.receiver
      owner = receiver ? lexical(receiver) : nesting_owner
      return owner if !@subject.singleton || @subject.chain.last == [:sclass, nil]

      owner.singleton_class
    end

    def nesting_owner
      @subject.chain.reduce(Object) do |mod, (kind, name)|
        kind == :sclass ? mod.singleton_class : mod.const_get(name)
      end
    end

    # A constant as the code naming it sees it: from the innermost nesting outward.
    def lexical(name)
      nestings = @subject.chain.filter_map(&:last).reduce([Object]) do |found, part|
        found << found.last.const_get(part)
      end
      nestings.reverse.find { |mod| mod.const_defined?(name) }
        .const_get(name)
    end

    def visibility_of(owner)
      return :private if owner.private_method_defined?(@name, false)
      return :protected if owner.protected_method_defined?(@name, false)

      :public
    end
  end
end
