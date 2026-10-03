# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe Mutato::Subjects do
  let(:source) do
    <<~RUBY
      module Sample
        class Registry
          class << Sample
            def answer(x)
              x * 2
            end
          end

          class << self
            def size(x)
              x + 1
            end
          end

          def <=>(other)
            size <=> other.size
          end

          def to_s
            "registry"
          end
        end
      end
    RUBY
  end
  let(:skips) do
    Mutato::Generation.new("lib/sample.rb", source).generator.subjects.to_h do |subject|
      [subject.name, subject.skip]
    end
  end

  it "skips a method in the singleton class of another object" do
    expect(skips[:answer]).to eq("explicit receiver")
  end

  it("keeps a method in `class << self`") { expect(skips[:size]).to be_nil }
  it("keeps a comparison") { expect(skips[:<=>]).to be_nil }
  it("skips to_s") { expect(skips[:to_s]).to eq("arid method name") }
end
