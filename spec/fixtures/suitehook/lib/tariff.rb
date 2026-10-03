# Configured from before(:suite); spec/mutato/cli_suitehook_spec.rb pins how it is judged.
class Tariff
  def self.configure(rate)
    @rate = rate + 3
  end

  def self.fee
    @rate
  end
end
