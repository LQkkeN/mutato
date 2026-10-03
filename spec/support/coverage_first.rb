# frozen_string_literal: true

# Loaded through RUBYOPT, it starts coverage before mutato does, as a coverage
# tool would.
require "coverage"
Coverage.start(lines: true)
