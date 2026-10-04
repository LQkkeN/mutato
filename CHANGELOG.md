# Changelog

Notable changes for users of mutato. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow
[Semantic Versioning](https://semver.org/).

## [Unreleased]

### Fixed

- Without `bundle exec`, below the Gemfile's directory, Bundler's switch to
  the locked version no longer restarts mutato without its arguments.
- Source files are read as UTF-8 whatever the locale.
- RSpec failure backtraces keep a project's own frames when its path contains
  `/mutato/`.

## [0.1.0] - 2026-10-03

### Added

- First release: mutation testing for RSpec, on Ruby 3.2 and later.
