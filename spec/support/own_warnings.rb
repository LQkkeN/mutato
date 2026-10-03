# frozen_string_literal: true

# Ruby's warnings from mutato's own code and specs fail the run; the gems' only print.
module OwnWarnings
  ROOT = File.expand_path("../..", __dir__)
  OWN = %w[lib exe spec].map { |dir| File.join(ROOT, dir, "") }
    .freeze
  FIXTURES = File.join(ROOT, "spec", "fixtures", "")
  private_constant :ROOT, :OWN, :FIXTURES

  def warn(message, ...)
    raise message.to_s if message.start_with?(*OWN) && !message.start_with?(FIXTURES)

    super
  end
end
