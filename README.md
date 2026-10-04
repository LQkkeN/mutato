<p align="center"><img src=".github/mutato.svg" width="150" alt=""></p>

# mutato

[![CI](https://github.com/LQkkeN/mutato/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/LQkkeN/mutato/actions/workflows/ci.yml)

Mutation testing for Ruby and RSpec. mutato changes your code one small step
at a time and runs the tests that cover each change. A change that no test
notices points at a missing test.

## Install

```ruby
# Gemfile
group :test do
  gem 'mutato'
end
```

Ruby 3.2 or later.

## Find what your tests miss

Take this class, with specs for VAT on 100 and for a discount of 20:

```ruby
# lib/shop/price.rb
module Shop
  class Price
    def initialize(amount, vat: 0.25)
      @amount = amount
      @vat = vat
    end

    def total(discount: 0)
      net = [@amount - discount, 0].max
      (net * (1 + @vat)).round(2)
    end
  end
end
```

```
$ bundle exec mutato run lib
14 mutants over 1 files, 2 methods
...
    7/14 caught      0.02s da2574057ce7  lib/shop/price.rb:9:14: [element] drop `@amount - discount`
    8/14 missed      0.01s 4c1d0b45c1fc  lib/shop/price.rb:9:34: [element] drop `0`
...
results: caught 11, missed 3

MISSED:
  4c1d0b45c1fc  lib/shop/price.rb:9:34: [element] drop `0`
  5315afcd609d  lib/shop/price.rb:10:26: [swap-method] replace `.round` with `.floor`
  efc60b287f00  lib/shop/price.rb:10:26: [swap-method] replace `.round` with `.ceil`
```

Each missed mutant is a change no test noticed: no spec gives a discount
larger than the amount, and none checks rounding up and down. Add those two
specs, then rerun just these mutants by id:

```
$ bundle exec mutato run lib --only 4c1d0b45c1fc,5315afcd609d,efc60b287f00
...
     1/3 caught      0.03s 4c1d0b45c1fc  lib/shop/price.rb:9:34: [element] drop `0`
     2/3 caught      0.03s 5315afcd609d  lib/shop/price.rb:10:26: [swap-method] replace `.round` with `.floor`
     3/3 caught      0.02s efc60b287f00  lib/shop/price.rb:10:26: [swap-method] replace `.round` with `.ceil`
results: caught 3
```

The exit code is 2 while anything is missed. An id stays the same while its
method is unchanged and the path is written the same way (`lib` and `./lib`
differ).

## See what would be tried

```
$ bundle exec mutato list lib
27f4e8ead8ca  lib/shop/price.rb:4:7: [value] replace body of Shop::Price#initialize with nil  (Shop::Price#initialize)
f7bfadab08e0  lib/shop/price.rb:4:7: [statement] delete statement `@amount = amount`  (Shop::Price#initialize)
...
14 mutants over 1 files, 2 methods
```

## Only what a branch changed

```sh
git diff -U0 origin/main | bundle exec mutato run lib --diff -
hg diff -U0 -r default | bundle exec mutato run lib --diff -
jj diff --git | bundle exec mutato run lib --diff -
bundle exec mutato run lib --diff changes.diff
```

Any unified diff works; mutato never calls a version control system itself.
It reads the diff's paths from the current directory, so from a subdirectory
of the repository use `git diff --relative`.

## On a GitHub pull request

```yaml
- uses: actions/checkout@v7
  with:
    fetch-depth: 0     # git diff needs the base commit
- run: git diff -U0 ${{ github.event.pull_request.base.sha }} |
       bundle exec mutato run lib --diff - --format github
  shell: bash          # pipefail: a failing git diff fails the step
```

Survivors show as warnings on the changed lines, timeouts as notices, and a
table of survivors goes into the step summary. Elsewhere, `--format plain`
prints lines that editors and CI systems parse:

```
lib/shop/price.rb:9:34: survived: drop `0`
```

## Choose the specs

```sh
bundle exec mutato run lib --spec spec/unit                        # default: spec
bundle exec mutato run app lib --spec 'spec --tag ~slow'           # any rspec arguments
bundle exec mutato run lib --spec "test --pattern '**/*_test.rb'"  # files not named _spec.rb
```

## Start small on a big codebase

```sh
bundle exec mutato run lib/billing                        # one directory or file
bundle exec mutato run lib --sample 50                    # 50 at random, the same 50 every time
bundle exec mutato run lib --limit 20                     # the first 20 in file order
bundle exec mutato run lib --genre arithmetic,relational  # only some kinds of change
```

## Check the setup

```
$ bundle exec mutato control lib --sample 40
...
control OK: 2 of 2 reinstalled methods passed their tests
```

`control` puts methods back unchanged and runs their tests. All must pass: a
method whose tests fail even then gives meaningless results in a real run.

## Project hooks

`.mutato.rb` in the project root, or `--config FILE`:

```ruby
# Tables cleaned in after hooks: a killed child leaves rows behind.
Mutato.before_mutant { truncate_tables }

# Rails loads lazily: load everything once, or untested files come out unloaded.
Mutato.after_boot { Rails.application.eager_load! }

# A socket must not be shared with the forked children.
Mutato.before_fork { SomeClient.disconnect }
Mutato.after_fork { SomeClient.connect }

# Accept a known survivor, with the reason on record; `mutato list` shows it.
Mutato.skip 'Accounts#obtain', 'lock re-check for a race no test reproduces'

# The project's own output calls, never worth mutating.
Mutato.arid :say, 'UI'
```

Sequel and ActiveRecord connections are closed before every fork already; an
in-memory SQLite database under Active Record is copied into each child instead.
Other options: `--out DIR` (default `mutato.out`), `--timeout-min SECONDS`
(default 10), `--version`, `--help`.

## Reading the results

`mutato.out/missed.txt` is the list to act on. Every other outcome has a list
too, `outcomes.json` holds all of them, and `logs/` has one log per mutant
with whatever the tests printed, capped at 1 MB.

| outcome | meaning |
|---|---|
| caught | a test failed, and passes without the mutant |
| missed | no test failed: a test is missing |
| timeout | the tests ran past five times their usual time, often an infinite loop |
| unjudged | only flaky tests cover it |
| equivalent | provably no change: a removed `super` into an `initialize` that does nothing |
| uncovered | no test runs the line |
| load-time | the code runs only while the suite loads |
| unloaded | the suite never loads the file |
| overwritten | the tests redefined the method, as a code reloader does |
| unviable | the mutant did not load |

Exit codes: 2 when a mutant is missed or unjudged, 3 when there is nothing to
mutate (0 with `--diff`), 1 on errors, otherwise 0. `control` exits 1 when a
method fails and 3 when no test ran any.

## What it changes

| genre | for example |
|---|---|
| statement | delete `@vat = vat` |
| condition | `if paid?` -> `if true`, `a && b` -> `a \|\| b`, `!x` -> `x` |
| relational | `a < b` -> `a <= b`, `a != b`, `false` |
| arithmetic | `a + b` -> `a - b`, `x += 1` -> `x -= 1`, `a - b` -> `b - a` |
| swap-method | `.round` -> `.floor`, `.max` -> `.min`, `.any?` -> `.all?` |
| value | a method's body -> `nil`, `[]`, `0`, `true` or `false` |
| element | `[net, 0]` -> `[net]` |

It leaves alone what no test could tell apart or should check: logging and
output, variables nothing reads, memo guards such as `return @x if @x`, line
offsets such as `__LINE__ + 1`, and code outside methods.
`mutato list` names each method it skips, with the reason.

## Limits

RSpec only, and one worker: a run takes as long as the tests it runs. An
endless `def x = ...` comes out uncovered, and native extensions are
invisible. A mutant can reach code the tests never did, such as the network.

## Licence

MIT.
