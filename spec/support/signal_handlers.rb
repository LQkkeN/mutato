# frozen_string_literal: true

# A campaign installs its own INT and TERM handlers; specs put RSpec's back.
RSpec.shared_context("with the signal handlers restored") do
  around do |example|
    previous = %w[INT TERM].to_h { |signal| [signal, trap(signal, "DEFAULT")] }
    example.run
  ensure
    previous.each { |signal, handler| trap(signal, handler || "DEFAULT") }
  end
end
