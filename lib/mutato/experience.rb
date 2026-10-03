# frozen_string_literal: true

module Mutato
  # culprits: per test sequence, the test that failed it unmutated, or nil when it passed.
  Experience = Struct.new(:flaky, :culprits) do
    def self.fresh
      new(Set.new, {})
    end
  end
  public_constant :Experience
end
