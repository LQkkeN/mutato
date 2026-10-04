# frozen_string_literal: true

require_relative "lib/mutato/version"

Gem::Specification.new do |spec|
  spec.name = "mutato"
  spec.version = Mutato::VERSION
  spec.authors = ["Mathias Løkke Madsen"]
  spec.summary = "Mutation testing for Ruby: boot once, fork per mutant"
  spec.description = <<~DESCRIPTION
    Mutates methods with Prism, redefines them in forked children of a
    test process booted once, selects the tests that cover each mutant from
    per-test coverage, and reports the survivors. RSpec or Minitest.
  DESCRIPTION
  spec.homepage = "https://github.com/LQkkeN/mutato"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2"

  spec.files = Dir["lib/**/*.rb", "exe/*", "LICENSE", "README.md", "CHANGELOG.md"]
  spec.bindir = "exe"
  spec.executables = ["mutato"]

  # 1.4 mis-slices `foo(&block)`.
  spec.add_dependency "prism", ">= 1.8"
  spec.metadata = {
    "source_code_uri" => spec.homepage,
    "changelog_uri" => "#{spec.homepage}/blob/main/CHANGELOG.md",
    "bug_tracker_uri" => "#{spec.homepage}/issues",
    "rubygems_mfa_required" => "true"
  }
end
