# frozen_string_literal: true

# The harness runs around every example: a mutant there changes the measurement, not the test.
Mutato.skip(
  /\AMutato::(?:Boot|Child|Watchdog|Run|RSpecAdapter|Result|CoverageListener|Tally|GroupHooks|Hits|Clock)\b/,
  "test harness: runs around the examples themselves"
)
Mutato.skip("Mutato::Config#run_hooks", "test harness: runs around the examples themselves")
Mutato.skip(/\AMutato::Installer\b/, "test harness: installs the mutants")
Mutato.skip("Mutato::Diff#initialize", "initial values a header always replaces")
Mutato.skip("Mutato::Generation#parses?", "safety net without a known case")
