require 'minitest/autorun'

class SampleTest < Minitest::Test
  def test_passes = assert(true)
  def test_fails = flunk('on purpose')
  def test_skips = skip('not here')
end
