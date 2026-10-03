# Where `super` goes from each `initialize`; spec/mutato/equivalence_spec.rb
# pins which removals provably change nothing.
module Supers
  class Empty
    def initialize
      super()
      @empty = true
    end
  end

  class Bare
    def initialize
      super
      @bare = true
    end
  end

  # Never built: a bare `super` passes `x` on, which Object would refuse.
  class Passing
    def initialize(x)
      super
      @x = x
    end
  end

  class Child < Empty
    def initialize
      super()
      @child = true
    end
  end

  module Mixed
    def initialize
      super()
      @mixed = true
    end
  end

  Pair = Struct.new(:left, :right)

  class Paired < Pair
    def initialize
      super()
      @paired = true
    end
  end

  Named = Struct.new(:name) do
    def initialize(*)
      super
      self.name ||= "none"
    end
  end

  class Renamed < Named
    def initialize
      super()
      @renamed = true
    end
  end
end
