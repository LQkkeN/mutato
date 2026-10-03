# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe Mutato::Generator do
  subject(:generator) { described_class.read(FixtureRuns.path("lib/calc.rb")) }

  let(:mutations) { generator.mutations }
  let(:descriptions) { mutations.map(&:description) }
  let(:reasons) do
    generator.subjects.select(&:skip).to_h do |subject|
      [subject.name, subject.skip]
    end
  end

  def line_of(text)
    generator.source.lines.index { |line| line.include?(text) } + 1
  end

  it "produces every planned genre" do
    expect(mutations.map(&:genre).uniq).to include(
      :statement,
      :condition,
      :relational,
      :arithmetic,
      :value,
      :element
    )
  end

  it "produces only valid Ruby" do
    mutations.each do |mutation|
      expect(Prism.parse(mutation.apply(generator.source)).errors).to be_empty, mutation.label
    end
  end

  it "leaves a guarded logging statement alone, but for the whole-body replacement" do
    on_line = mutations.select { |mutation| mutation.start_line == line_of("logger.debug") }
    expect(on_line.map(&:genre).uniq).to eq([:value])
  end

  it "replaces the body of a method with a rescue clause too" do
    expect(
      mutations.select do |mutation|
        mutation.subject.name == :ratio && mutation.genre == :value
      end
    ).to be_one
  end

  it "skips template stubs and logging helpers" do
    expect(reasons).to eq(abstract: "template stub", logger: "logging helper")
  end

  it "mutates the body of a Struct a constant names" do
    expect(mutations.map { |mutation| mutation.subject.to_s }).to include("Fixture::Calc::Pair#doubled")
  end

  it "gives every mutant a distinct id" do
    expect(mutations.map(&:id)).to eq(mutations.map(&:id).uniq)
  end

  it "places an operator's mutant at the operator, and labels it so" do
    plus = mutations.find { |mutation| mutation.description == "replace `+` with `-`" }
    expect(plus.label).to end_with("calc.rb:10:9: [arithmetic] replace `+` with `-`")
  end

  it "gives the same ids on every run" do
    expect(described_class.read(generator.file).mutations.map(&:id)).to eq(mutations.map(&:id))
  end

  context "with a block stored while the file loads" do
    let(:inside) { mutations.find { |mutation| mutation.description.include?("x * 2") } }
    let(:outside) do
      mutations.find do |mutation|
        mutation.description.include?("return low if x < low")
      end
    end

    it "judges a mutant inside by the statement holding the block" do
      expect(inside.outer_lines).to eq(line_of("define_method")..(line_of("x * 2") + 1))
    end

    it("judges a mutant outside by its own lines") { expect(outside.outer_lines).to be_nil }

    it "knows the lines inside the block" do
      expect(inside.subject.block_lines).to eq([line_of("x * 2"), line_of("x * 2") + 1])
    end
  end

  context "with trailing commas, heredocs, guards and logging helpers" do
    subject(:generator) { described_class.read(FixtureRuns.path("lib/edge.rb")) }

    let(:on_guard) do
      mutations.select do |mutation|
        mutation.line == line_of("if x.nil?") && mutation.genre != :value
      end
    end

    it("drops no mutant as unparsable") { expect(generator.dropped).to be_empty }
    it("drops an element before a trailing comma") { expect(descriptions).to include("drop `2`") }

    it "takes a heredoc's body along when it deletes its statement" do
      deletion = mutations.find do |mutation|
        mutation.description.start_with?("delete statement `raise")
      end
      expect(deletion.apply(generator.source)).not_to include("x is required")
    end

    it "selects the tests for an element through its whole statement" do
      expect(
        mutations.find { |mutation| mutation.description == "drop `1`" }
        .span
      ).to eq(4..7)
    end

    it "deletes a heredoc whole" do
      expect(descriptions).to include(a_string_including("`raise ArgumentError, <<~MSG"))
    end

    it "leaves the expression inside an interpolation alone" do
      expect(descriptions).not_to include("delete statement `x`")
    end

    it "leaves a memoization guard alone" do
      expect(descriptions).not_to include(a_string_including("return @cached"))
    end

    it "makes two mutants of a guard, not four" do
      expect(on_guard.map(&:description))
        .to contain_exactly(
          a_string_starting_with("delete statement `raise"),
          "replace condition `x.nil?` with true"
        )
    end

    it "skips logging helpers and methods that only log" do
      expect(reasons).to eq(
        log_result: "logging only",
        warn_if_slow: "logging only",
        fleeting: "defined inside a block",
        logger: "logging helper"
      )
    end
  end

  context "with every construct the generator treats specially" do
    subject(:generator) { described_class.read(FixtureRuns.path("lib/more.rb")) }

    let(:by_method) do
      grouped = mutations.group_by { |mutation| mutation.subject.name }
      grouped.transform_values { |group| group.map(&:description) }
    end

    def body_of(name)
      "replace body of Fixture::More##{name} with nil"
    end

    # What each whole-body replacement puts in place of the body.
    def replacements(name)
      by_method.fetch(name).grep(/\Areplace body/).map { |text| text.split.last }
    end

    it "mutates nothing in a method that only logs, but its body" do
      expect(by_method.fetch(:chatter)).to eq([body_of(:chatter)])
    end

    it "keeps a loop that only logs" do
      expect(by_method.fetch(:after_block)).to eq([body_of(:after_block), "replace `+` with `-`"])
    end

    it "keeps an empty conditional" do
      expect(by_method.fetch(:noop)).to eq([body_of(:noop)])
    end

    it "mutates nothing inside a store no one reads" do
      expect(by_method.fetch(:bump)).to eq([body_of(:bump)])
    end

    it "leaves a literal condition alone" do
      expect(by_method.fetch(:always)).to eq([body_of(:always)])
    end

    it "makes nothing of a body that is already nil" do
      expect(by_method).not_to have_key(:nothing)
    end

    it "deletes the stores something reads, instance variables included" do
      expect(by_method.fetch(:stores).grep(/\Adelete/)).to contain_exactly(
        "delete statement `kept = 2`",
        "delete statement `@kept = 3`",
        "delete statement `@unused = 2`",
        "delete statement `h[:v] = kept`"
      )
    end

    it "deletes the last statement of initialize and any super, but not a first nil" do
      expect(by_method.fetch(:initialize).grep(/\Adelete/)).to contain_exactly(
        "delete statement `super`",
        "delete statement `@kept = 0`",
        "delete statement `super()`",
        "delete statement `@x = x`",
        "delete statement `super(x)`",
        "delete statement `@x = x`"
      )
    end

    it "skips the body of a while loop with false and of an until loop with true" do
      expect(by_method.fetch(:loops))
        .to include("replace condition `x < 3` with false", "replace condition `x.zero?` with true")
    end

    it "only enables a guard it deletes" do
      expect(by_method.fetch(:guard))
        .to include("replace condition `x` with false")
        .and(exclude("replace condition `x` with true"))
    end

    it "swaps every connector, spelled either way" do
      expect(by_method.fetch(:words)).to include(
        "replace `and` with `or`",
        "replace `or` with `and`",
        "replace `&&` with `||`",
        "replace `||` with `&&`"
      )
    end

    it "flips equality on a count, but never a count that is positive to one that is not zero" do
      expect(by_method.fetch(:counts))
        .to include("replace `==` with `!=`", "replace `!=` with `==`")
        .and(exclude("replace `>` with `!=`"))
    end

    it "mutates an operator written as one, not a method call spelled out" do
      expect(by_method.fetch(:compare))
        .to eq([body_of(:compare), "replace `||` with `&&`", "replace `==` with `!=`"])
    end

    it "mutates arithmetic inside interpolation without deleting the expression" do
      expect(by_method.fetch(:interpolated).grep(/\A(?:replace `|delete)/))
        .to eq(["replace `+` with `-`", "replace `*` with `/`", "replace `-` with `+`"])
    end

    it "flips compound assignments" do
      expect(by_method.fetch(:two_step)).to include(
        "replace `+=` with `-=`",
        "replace `-=` with `+=`"
      )
    end

    it "swaps methods for their opposite numbers" do
      expect(by_method.fetch(:extremes).grep(/\Areplace `\./).size).to eq(14)
    end

    it "swaps first and last only as an Array's own" do
      expect(by_method.fetch(:ends).grep(/\Areplace `\./)).to eq(["replace `.first` with `.last`"])
    end

    it "drops elements from literals of up to ten" do
      drops = %i[one ten eleven].map { |name| by_method.fetch(name).grep(/\Adrop/).size }
      expect(drops).to eq([0, 10, 0])
    end

    it "drops no nil or false element" do
      expect(by_method.fetch(:sparse).grep(/\Adrop/))
        .to eq(["drop `a: 1`", "drop `d: [1, nil]`", "drop `1`"])
    end

    it "replaces a body by the empty value of its type, or by its opposite" do
      expect(%i[positive? flag opts].map { |name| replacements(name) })
        .to eq([%w[true false], %w[nil true], %w[nil {}]])
    end

    it "names every method as Ruby would" do
      expect(generator.subjects.map(&:to_s)).to include(
        "Fixture::Thing#z",
        "Fixture::Util.u",
        "Fixture::Point#dbl",
        "Fixture::More.named",
        "Fixture::More.shared",
        "Fixture::Nested::Deeper.depth",
        "Thing.made"
      )
    end

    it "says why it leaves methods alone" do
      expect(reasons).to eq(
        to_s: "arid method name",
        described_for_log: "only used in logging",
        settings: "only used in logging",
        log: "logging helper",
        logger: "logging helper",
        log_error: "logging helper",
        registered: "defined inside a block",
        foreign: "explicit receiver"
      )
    end

    it "mutates a public method only used in logging: another file may call it" do
      names = mutations.map { |mutation| mutation.subject.name }
      expect(names).to include(:described_elsewhere_too)
    end

    it "gives every mutant a distinct id" do
      expect(mutations.map(&:id)).to eq(mutations.map(&:id).uniq)
    end

    it "makes each change once, whichever genre finds it first" do
      changes = mutations.map { |mutation| [mutation.offset, mutation.bytes, mutation.replacement] }
      expect(changes).to eq(changes.uniq)
    end

    it "deletes a call on a subscript that names no logger" do
      expect(by_method.fetch(:tidy)).to include("delete statement `table[:name].strip!`")
    end

    it "keeps `!=` for a call compared that is no count" do
      expect(by_method.fetch(:larger)).to include("replace `>` with `!=`")
    end

    it "deletes a call with no receiver that is not logging" do
      expect(by_method.fetch(:remember)).to include("delete statement `store(x)`")
    end

    it "deletes a call whose block only logs when the call is no loop" do
      expect(by_method.fetch(:touch)).to include(a_string_starting_with("delete statement `File"))
    end

    it "mutates calls on constants that are no loggers" do
      expect(by_method.fetch(:root)).to include("replace `+` with `-`")
    end

    it "replaces the condition of a deleted if with an else both ways" do
      expect(by_method.fetch(:choose))
        .to include("replace condition `x > 1` with true", "replace condition `x > 1` with false")
    end

    it "deletes each statement of a branch that holds several" do
      expect(by_method.fetch(:mixed)).to include("delete statement `x += 1`")
    end

    it "deletes the statements of both branches" do
      expect(by_method.fetch(:pick)).to include(
        "delete statement `x.abs`",
        "delete statement `x.to_s`"
      )
    end

    it "flips no compound operator that has no opposite" do
      expect(by_method.fetch(:modulo)).to eq([body_of(:modulo), "delete statement `x %= 3`"])
    end

    it "swaps the operands of a division" do
      expect(by_method.fetch(:safe_div)).to include("swap operands of `/`")
    end

    it "keeps the last statement of a method with a rescue" do
      expect(by_method.fetch(:safe_div)).not_to include("delete statement `quotient.to_s`")
    end

    it "replaces a comparison by the literal it can become" do
      expect(by_method.fetch(:counts)).to include("replace `items.size > 0` with false")
    end

    it "keeps `!=` for a comparison that is no count" do
      expect(by_method.fetch(:positive?)).to include("replace `>` with `!=`")
    end

    it "deletes super outside initialize" do
      expect(by_method.fetch(:extra)).to include("delete statement `super`")
    end

    it "drops a negation" do
      expect(by_method.fetch(:extremes)).to include("drop `!` from `!list`")
    end

    it "guesses the empty value from the last statement" do
      expect(replacements(:extra)).to eq(%w[nil 0])
    end

    it "judges a mutant after a block by its own statement" do
      after = mutations.reverse.find { |mutation| mutation.subject.name == :after_map }
      expect([after.description, after.outer_lines]).to eq(["replace `+` with `-`", nil])
    end
  end
end
