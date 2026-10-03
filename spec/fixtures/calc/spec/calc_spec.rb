require_relative '../lib/calc'

RSpec.describe Fixture::Calc do
  subject(:calc) { described_class.new }

  it('adds') { expect(calc.add(2, 3)).to eq(5) }
  it('doubles') { expect(calc.double(2)).to eq(4) }
  it('clamps below') { expect(calc.clamp(-1, 0, 10)).to eq(0) }
  # Deliberately no example clamps above: those mutants must survive.
  it('passes through') { expect(calc.clamp(5, 0, 10)).to eq(5) }
  it('describes') { expect(calc.describe([1])).to eq('1 items') }
  it('describes nothing') { expect(calc.describe([])).to eq('none') }
  it('divides') { expect(calc.ratio(6, 3)).to eq(2) }
  it('divides by zero') { expect(calc.ratio(1, 0)).to eq(0) }
end
