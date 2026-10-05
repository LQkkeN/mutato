require 'minitest/autorun'

# A class-level hook around the class's tests, as a before_all hook is.
class HookedTest < Minitest::Test
  def self.with_info_handler(*, &)
    @ready = true
    super
  ensure
    @ready = false
  end

  def self.ready? = @ready

  def test_sees_the_class_hook = assert(self.class.ready?)
end
