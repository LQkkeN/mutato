# One method per outcome mutato can report; spec/mutato/cli_outcomes_spec.rb
# pins what each comes out as.
module Outcomes
  # A class method: the mutant must be installed on the singleton class.
  def self.twice(x)
    x * 2
  end

  # Without `i += 1` the loop never ends; the soft timeout stops it.
  class Loop
    def count(n)
      i = 0
      i += 1 while i < n
      i
    end
  end

  # The same loop, but the code swallows the soft timeout: only the hard kill
  # stops it.
  class Stubborn
    def count(n)
      i = 0
      begin
        i += 1 while i < n
      rescue Exception
        retry
      end
      i
    end
  end

  # A mutant that exits the process.
  class Quits
    def check(x)
      exit(1) unless x
      x
    end
  end

  # A mutant that signals its own process.
  class Signals
    def check(x)
      Process.kill("TERM", Process.pid) if x.nil?
      x
    end
  end

  # Its test loads this file again, over the installed mutant.
  class Reloaded
    def value
      1 + 1
    end
  end

  # Its test passes only the first time it runs.
  class Flaky
    def value
      1 + 2
    end
  end

  # Defined on its class by name, which is `def self.answer`.
  class Named
    def Named.answer
      40 + 2
    end
  end

  # Defined on a class beside the one it is written in.
  class Elsewhere
    def Named.question
      6 * 7
    end
  end

  # Its test holds the method object from load time, so even reinstalling the
  # method unchanged fails it: a control run must say so.
  class Pinned
    def same?
      true
    end

    ORIGINAL = instance_method(:same?)
  end

  # Its `super()` reaches the empty BasicObject#initialize; removing it
  # provably changes nothing.
  class Plain
    def initialize
      super()
      @ready = true
    end

    def ready?
      @ready
    end
  end

  # Its `super()` reaches Plain's.
  class Built < Plain
    def initialize
      super()
      @built = true
    end
  end
end
