# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe Mutato::Privates do
  def names(body)
    statements = Prism.parse("class Probe\n#{body}\nend\n").value.statements.body.first.body
    described_class.names(statements)
  end

  {
    "the defs after a bare private" => ["def a; end\nprivate\ndef b; end", [:b]],
    "them up to public" => ["private\ndef b; end\npublic\ndef c; end", [:b]],
    "them up to protected" => ["private\ndef b; end\nprotected\ndef c; end", [:b]],
    "private def" => ["private def b; end\ndef c; end", [:b]],
    "symbols and strings listed" => ["def b; end\ndef c; end\nprivate :b, \"c\"", %i[b c]],
    "nothing from public :b" => ["def b; end\npublic :b", []],
    "nothing from a computed name" => ["private helper_names", []],
    "nothing from a call that only looks alike" => ["x.private\ndef b; end", []]
  }.each do |what, (body, expected)|
    it("takes #{what}") { expect(names(body)).to eq(expected) }
  end
end
