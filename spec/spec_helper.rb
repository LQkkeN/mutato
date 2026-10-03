# frozen_string_literal: true

require_relative "support/own_warnings"

Warning.singleton_class.prepend(OwnWarnings)
$VERBOSE = true
Warning[:deprecated] = true
Warning[:performance] = true if RUBY_VERSION >= "3.3"

require_relative "../lib/mutato"
require_relative "../lib/mutato/cli"
require_relative "support/fixture_runs"
require_relative "support/one_test_suite"
require_relative "support/records"
require_relative "support/scratch"
require_relative "support/signal_handlers"

RSpec::Matchers.define_negated_matcher(:exclude, :include)

RSpec.configure do |config|
  config.disable_monkey_patching!
  config.raise_errors_for_deprecations!
  config.raise_on_warning = true
  config.order = :random
  Kernel.srand(config.seed)
  config.expect_with(:rspec) do |expectations|
    expectations.syntax = :expect
    expectations.strict_predicate_matchers = true
    expectations.on_potential_false_positives = :raise
  end
  config.mock_with(:rspec) do |mocks|
    mocks.verify_partial_doubles = true
    mocks.verify_doubled_constant_names = true
  end
end
