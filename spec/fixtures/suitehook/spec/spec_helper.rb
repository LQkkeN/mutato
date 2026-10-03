require_relative "../lib/tariff"
require_relative "../lib/greeter"

RSpec.configure { |config| config.before(:suite) { Tariff.configure(7) } }
