require 'minitest/autorun'
require_relative '../lib/calc'

# One marker per process that runs the after_run blocks.
Minitest.after_run { File.write(File.join(ENV.fetch('FIXTURE_TMP'), "after_run-#{Process.pid}"), '') }

class CalcTest < Minitest::Test
  def setup
    @calc = Fixture::Calc.new
  end

  def test_adds = assert_equal(5, @calc.add(2, 3))
  def test_doubles = assert_equal(4, @calc.double(2))
  def test_clamps_below = assert_equal(0, @calc.clamp(-1, 0, 10))
  # Deliberately no test clamps above: those mutants must survive.
  def test_passes_through = assert_equal(5, @calc.clamp(5, 0, 10))
  def test_describes = assert_equal('1 items', @calc.describe([1]))
  def test_describes_nothing = assert_equal('none', @calc.describe([]))
  def test_divides = assert_equal(2, @calc.ratio(6, 3))
  def test_divides_by_zero = assert_equal(0, @calc.ratio(1, 0))
  def test_skipped = skip('covers nothing')
end
