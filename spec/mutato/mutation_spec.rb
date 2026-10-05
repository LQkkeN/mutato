# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe Mutato::Mutation do
  subject(:minus) { OneTestSuite.minus }

  let(:source) { File.read(OneTestSuite::CALC) }
  let(:add) { minus.subject }
  let(:control) { described_class.control(add) }

  it "labels itself with its place, genre and description" do
    expect(minus.to_s).to end_with("calc.rb:10:9: [arithmetic] replace `+` with `-`")
  end

  it "lists itself with its id and method" do
    expect(minus.listing).to match(/\A\h{12}  .*  \(Fixture::Calc#add\)\z/)
  end

  it("spans the lines of its statement") { expect(minus.span).to eq(10..10) }
  it("names its lines as coverage does") { expect(minus.line_keys).to eq(["#{OneTestSuite::CALC}:10"]) }
  it("changes the file's source") { expect(minus.apply(source).lines[9]).to eq("      a - b\n") }

  it "gives the method's own source, changed" do
    expect(minus.mutated_source(source)).to eq("def add(a, b)\n      a - b\n    end")
  end

  it "starts its outcome from what it is and the tests that cover it" do
    expect(minus.record(%w[t1])).to include(
      id: minus.id,
      file: minus.file,
      genre: :arithmetic,
      line: 10,
      col: 9,
      description: "replace `+` with `-`",
      examples: 1,
      ids: %w[t1],
      seconds: 0.0
    )
  end

  it("names a control after its method") { expect(control.id).to eq("control-Fixture::Calc#add") }

  it "changes nothing as a control" do
    expect(control.mutated_source(source)).to eq(add.node.slice)
  end

  it "starts a control's span below the def line, which runs at load" do
    expect(control.span).to eq(10..11)
  end

  it "describes a control" do
    expect(control.description).to eq("reinstall Fixture::Calc#add unchanged")
  end
end
