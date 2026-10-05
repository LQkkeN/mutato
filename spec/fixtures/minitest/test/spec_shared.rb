require 'minitest/autorun'

# Two classes of one name, as two describe blocks of one title make.
[1, 2].each do |value|
  Minitest::Spec.create('Shared', nil).class_eval do
    it('counts') { _(value).must_equal value }
  end
end
