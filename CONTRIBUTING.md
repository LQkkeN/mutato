# Contributing

```sh
bundle install
bundle exec rake
```

`rake` runs the specs, RuboCop, Reek, Flay, and mutato on its own code; all of
it must pass, with no surviving mutant. CI runs it on Ruby 3.2, 3.3, 3.4 and
4.0.

When a change to the generator changes what it makes of the fixture, the
recorded listing fails. Record it again and review the diff:

```sh
RECORD=1 bundle exec rspec spec/mutato/selection_spec.rb
git diff spec/fixtures/calc/mutants.txt
```

## Changelog

A pull request that changes `lib/`, `exe/` or the gemspec also changes
`CHANGELOG.md`: a line under `## [Unreleased]`, in the section that fits,
Added, Changed, Deprecated, Removed, Fixed or Security. A change users cannot
notice, such as a refactor, gets the `no changelog` label instead. CI checks
this on every pull request.

## Commit messages

A subject of at most 50 characters, capitalized, without a final period; a
blank line; a body wrapped at 72. A hook checks it as you commit:

```sh
git config core.hooksPath .githooks
```

## Releases

1. In a pull request, bump `lib/mutato/version.rb` and rename `[Unreleased]` to
   `## [x.y.z] - YYYY-MM-DD`, with a new empty `[Unreleased]` above it. CI
   refuses a version without its heading.
2. Merge it, then tag the merge commit and push the tag:

   ```sh
   git tag -s vX.Y.Z -m 'mutato X.Y.Z'
   git push origin vX.Y.Z
   ```

3. Approve the `release` environment; the workflow publishes to RubyGems.
