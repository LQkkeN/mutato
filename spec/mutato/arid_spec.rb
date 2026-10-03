# frozen_string_literal: true

require_relative "../spec_helper"

# What counts as output or logging, and so is left alone.
RSpec.describe Mutato::Arid do
  let(:generate) do
    lambda do |body|
      source = <<~RUBY
        class Probe
          def call(io, items, params, x)
        #{body}
          end

          def log_in(user)
            user
          end
        end
      RUBY
      Mutato::Generation.new("lib/probe.rb", source).generator
    end
  end
  let(:descriptions) { ->(body) { generate.call(body).mutations.map(&:description) } }

  it "mutates writing to an IO the code was handed" do
    expect(descriptions.call("io.puts(items.size + 1)\nx"))
      .to include("delete statement `io.puts(items.size + 1)`")
  end

  it "leaves writing to the console alone" do
    expect(descriptions.call("$stdout.puts(items.size + 1)\nx"))
      .not_to include("delete statement `$stdout.puts(items.size + 1)`")
  end

  it "mutates the work inside a logger's block" do
    body = "@logger.tagged('order') do\n  reserve(items)\n  x\nend\nx"
    expect(descriptions.call(body)).to include("delete statement `reserve(items)`")
  end

  it "leaves a logger call alone" do
    expect(descriptions.call("logger.warn('slow')\nx"))
      .not_to include("delete statement `logger.warn('slow')`")
  end

  it "mutates a comparison with a key that merely contains log" do
    expect(descriptions.call("params[:login] == x")).to include("replace `==` with `!=`")
  end

  it "mutates arithmetic on Math.log" do
    expect(descriptions.call("Math.log(x) / Math.log(2)")).to include("replace `/` with `*`")
  end

  it "mutates a method named like log_in" do
    skips = generate.call("x").subjects.to_h { |subject| [subject.name, subject.skip] }
    expect(skips[:log_in]).to be_nil
  end
end
