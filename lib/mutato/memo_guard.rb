# frozen_string_literal: true

module Mutato
  # `return @x if @x` and the like: deleting one, or making it never return, only skips a cache.
  module MemoGuard
    SET = 'if (?:\1|defined\?(?:\(\1\)| \1)|instance_variable_defined\?\(:\1\))|unless \1\.nil\?'
    PATTERN = /\Areturn (@\w+) (?:#{SET})\z/
    private_constant :SET, :PATTERN

    module_function

    def match?(statement)
      statement.slice.match?(PATTERN)
    end
  end
end
