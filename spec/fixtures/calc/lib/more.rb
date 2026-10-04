# Every construct the generator treats specially, in one place; mutato's own
# specs record what it makes of this file.
module Fixture
  Thing = Class.new do
    def z
      1
    end
  end

  Util = Module.new do
    def self.u
      2
    end
  end

  Point = Data.define(:x) do
    def dbl
      x * 2
    end
  end

  class More < Thing
    def initialize
      super
      @later = nil
      @kept = 0
    end

    def kept
      @kept
    end

    def stores(h)
      scratch = 1
      kept = 2
      @kept = 3
      @unused = 2
      h[:k] = nil
      h[:v] = kept
      h
    end

    def counts(items)
      [items.size > 0, items.length > 0, items.count > 0, items.length == 0, items.count != 1]
    end

    def ends(items)
      [items.first, items.first(2), items.last { true }, max, first(2)]
    end

    def mixed(x)
      if x
        puts(x)
        x += 1
      end
      x
    end

    def two_step(x)
      if x
        x += 1
        x -= 2
      end
      x
    end

    def bump(total)
      total = total + 1
      :done
    end

    def root(x)
      Math.sqrt(x + 1)
    end

    def long_steps(value)
      first = value.to_s.center(20).upcase.reverse.downcase.strip.squeeze.chars.sort.join.freeze.dup
      first.reverse
    end

    def after_block(list)
      list.each { |x| puts x }
      list.size + 1
    end

    def extra
      super
      1
    end

    def hint
      subclass_hint
    end

    def subclass_hint
      :hint
    end

    def extremes(list, n)
      [list.max, list.min, n.round, n.floor, n.ceil, n.truncate, list.any?, list.all?, list.none?, list.empty?, !list]
    end

    def compare(a, b)
      a.>(b) || -a == b
    end

    def loops(x)
      x += 1 while x < 3
      x -= 1 until x.zero?
      x
    end

    def words(a, b)
      (a and b) or (a && b) || (a or b)
    end

    def always
      true ? :yes : :no
    end

    def guard(x)
      raise ArgumentError unless x
      x >= 0 ? 1 : -1
    end

    def pick(x)
      if x > 0
        x.abs
      else
        x.to_s
      end
    end

    def noop(x)
      if x
      end
      x
    end

    def one
      [1]
    end

    def ten
      [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    end

    def eleven
      [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
    end

    def sparse
      { a: 1, b: nil, c: false, d: [1, nil] }
    end

    def call_with_keywords
      format("%<a>d %<b>d", a: 1, b: 2)
    end

    def interpolated(a, b)
      "#{a + b} and #{(a - b) * 2}"
    end

    def nothing
      nil
    end

    def positive?(x)
      x > 0
    end

    def flag
      false
    end

    def opts
      { a: 1 }
    end

    def long_statement(value)
      value.to_s.center(20).upcase.reverse.downcase.strip.squeeze.chars.sort.join.freeze.dup
    end

    def safe_div(a, b)
      quotient = a / b
      quotient.to_s
    rescue ZeroDivisionError
      "inf"
    end

    def self.inspect
      "More"
    end

    def to_s
      "more"
    end

    def More.named
      :named
    end

    class << self
      def shared
        :shared
      end
    end

    def chatter(x)
      puts(x + 1)
      @logger.info(x)
      $log.debug(x)
      Fixture::Logger.debug(x)
      settings[:logger].error(x)
      log_error(x)
      log.info(x)
      warn("x") unless x
      if x then puts 1 else puts 2 end
      logger.debug(described_for_log(x)) if x
      described_elsewhere(x)
    end

    private def described_for_log(x)
      x.to_s * 2
    end

    def described_elsewhere(x)
      logger.info(described_elsewhere_too(x))
      x.to_s * 3
    end

    def described_elsewhere_too(x)
      x
    end

    private def settings
      { logger: Logger }
    end

    def tidy(table)
      table[:name].strip!
      table
    end

    def log
      Logger
    end

    def logger
      Logger
    end

    def log_error(x)
      Logger.debug(x)
    end

    def quiet_unless(x)
      return 0 unless x
      logger.warn("x")
    end

    def remember(x)
      store(x)
      x
    end

    def store(x)
      x
    end

    def touch(path)
      File.open(path, "w") { |file| puts file }
      path
    end

    def choose(x)
      if x > 1 then x += 1 else x -= 1 end
      x
    end

    def modulo(x)
      x %= 3
      x
    end

    def triple(x) = x * 3

    def larger(items, n)
      items.first > n
    end

    def after_map(list)
      doubled = list.map { |x| x * 2 }
      doubled.size + 1
    end

    def listed(items)
      [
        "items:",
        *items.map do |item|
          item.to_s * 2
        end
      ]
    end

    def next_line
      __LINE__ + 1
    end

    def line_after
      1 + __LINE__
    end
  end

  REGISTRY = [].tap do
    def registered
      :yes
    end
  end

  class Less < Thing
    def initialize(x)
      super()
      @x = x
    end
  end

  class Least < Thing
    def initialize(x)
      super(x)
      @x = x
    end

    def Thing.made
      :made
    end
  end

  module Nested
  end

  class Nested::Deeper
    def Deeper.depth
      2
    end
  end

  o = Object.new
  def o.foreign
    :foreign
  end
end
