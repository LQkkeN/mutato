# frozen_string_literal: true

module Mutato
  # What a test framework's adapter answers; RSpecAdapter is one.
  module Adapter
    # Booting: load and name the tests, report a load error; a child measures them.
    BOOT = %i[boot locations load_failed? baseline].freeze
    # Running mutants: a child runs tests, names the one running, stops, ends; the parent ends.
    RUN = %i[run current stop child_done suite_done].freeze
    CALLS = (BOOT + RUN).freeze
    public_constant :BOOT, :RUN, :CALLS
  end
end
