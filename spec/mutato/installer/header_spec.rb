# frozen_string_literal: true

require_relative "../../spec_helper"

# A reinstalled method keeps what its file gave it: frozen literals, refinements, its path.
RSpec.describe Mutato::Installer::Header do
  let(:root) { File.expand_path("../../fixtures/framed", __dir__) }
  let(:reinstall) do
    lambda do |name|
      Dir.chdir(root) do
        method = Mutato::Generator.read("lib/framed.rb").subjects.find { |subject| subject.name == name }
        Mutato::Installer.install(method, method.node.slice)
      end
    end
  end

  before { require File.join(root, "lib/framed") }

  it "takes the frozen-string comment and the top-level using, and nothing else" do
    expect(described_class.of(File.join(root, "lib/framed.rb")))
      .to eq("# frozen_string_literal: true\nusing Shout; ")
  end

  it "keeps the file's string literals frozen" do
    reinstall.call(:label)
    expect(Framed.new.label).to be_frozen
  end

  it "keeps the file's refinements" do
    reinstall.call(:loud)
    expect(Framed.new.loud("hey")).to eq("HEY!")
  end

  it "gives __FILE__ the absolute path" do
    reinstall.call(:where)
    expect(Framed.new.where).to eq(File.join(root, "lib/framed.rb"))
  end
end
