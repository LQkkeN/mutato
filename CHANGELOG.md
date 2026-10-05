# Changelog

Notable changes for users of mutato. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow
[Semantic Versioning](https://semver.org/).

## [Unreleased]

## [0.2.0] - 2026-10-05

### Added

- Minitest 5 and 6: `--test PATHS`, or by default when there is a `test`
  directory and no `spec` one.

### Changed

- A baseline in which most of the tests that run the chosen mutants fail stops
  the run.
- `__LINE__ + 1` and the like are not mutated, nor are memo guards that test
  `defined?(@x)` or `@x.nil?`.

### Fixed

- Without `bundle exec`, below the Gemfile's directory, Bundler's switch to
  the locked version no longer restarts mutato without its arguments.
- Source files are read as UTF-8 whatever the locale.
- RSpec failure backtraces keep a project's own frames when its path contains
  `/mutato/`.
- A gem that defines the `ActiveRecord` namespace without Active Record no
  longer breaks the fork.
- Active Record on in-memory SQLite: each child gets a copy of the database,
  where it got an empty one.

## [0.1.0] - 2026-10-03

### Added

- First release: mutation testing for RSpec, on Ruby 3.2 and later.
