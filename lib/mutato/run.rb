# frozen_string_literal: true

module Mutato
  # Without a mutation, it confirms a kill.
  class Run
    def initialize(suite, mutation)
      @suite = suite
      @mutation = mutation
      @installed = nil
    end

    def go(ids, budget, log:)
      Mutato.config.run_hooks(:before_mutant)
      result = Child.run(timeout: budget + [budget, 5.0].max, log:) { in_child(ids, budget) }
      Output.cap(log)
      result
    end

    private

    def in_child(ids, budget)
      install
      checked(Watchdog.new(@suite.adapter, budget).run(ids))
    rescue Installer::Unviable => error
      { outcome: :unviable, detail: error.message }
    end

    def install
      return unless @mutation

      @installed = Installer.install(
        @mutation.subject,
        @mutation.mutated_source(File.read(@mutation.file))
      )
    end

    def checked(verdict)
      return verdict if verdict.fetch(:outcome) == :timeout || !@mutation
      return verdict if Installer.current(@mutation.subject) == @installed

      { outcome: :overwritten, detail: "the tests redefined the method (code reloader?)" }
    end
  end
end
