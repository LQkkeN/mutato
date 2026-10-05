# frozen_string_literal: true

require "sqlite3"
require_relative "../../spec_helper"
require_relative "../../support/stand_in_pool"

# Real SQLite behind stand-in connection pools; the fork itself is left out.
RSpec.describe Mutato::Integrations::ActiveRecord do
  let(:child) { SQLite3::Database.new(":memory:") }
  let(:memory) do
    fresh = StandInPool.new(%w[sqlite3 :memory:], raw: child)
    StandInPool.new(%w[sqlite3 :memory:], raw: parent, child: fresh)
  end
  let(:file) { StandInPool.new(%w[sqlite3 db/test.sqlite3]) }
  let(:other) { StandInPool.new(%w[postgresql :memory:]) }

  def parent
    @parent ||= SQLite3::Database.new(":memory:").tap do |db|
      db.execute_batch("create table t (x); insert into t values (42)")
    end
  end

  before { allow(described_class).to receive(:pools).and_return([memory, file, other]) }

  it "gives the child's new connection the parent's in-memory database" do
    described_class.before_fork
    described_class.after_fork
    expect(child.execute("select x from t")).to eq([[42]])
  end

  it "disconnects a file database" do
    expect { described_class.before_fork }
      .to change(file, :disconnected).to(true)
  end

  it "disconnects another adapter's" do
    expect { described_class.before_fork }
      .to change(other, :disconnected).to(true)
  end

  it "keeps a named in-memory database open too" do
    named = StandInPool.new(%w[sqlite3 file:memdb1?cache=shared&mode=memory], raw: parent)
    allow(described_class).to receive(:pools).and_return([named])
    expect { described_class.before_fork }
      .not_to change(named, :disconnected)
  end

  it "takes a file URI without mode=memory for a file" do
    named = StandInPool.new(%w[sqlite3 file:test.sqlite3?mode=rwc])
    allow(described_class).to receive(:pools).and_return([named])
    expect { described_class.before_fork }
      .to change(named, :disconnected).to(true)
  end

  it "keeps the in-memory one open" do
    expect { described_class.before_fork }
      .not_to change(memory, :disconnected)
  end

  it "closes the snapshot an earlier fork left" do
    described_class.before_fork
    earlier = described_class.instance_variable_get(:@snapshots).first.last
    described_class.before_fork
    expect(earlier).to be_closed
  end

  it "keeps sqlite3 from warning about the open handle a child inherits" do
    allow(SQLite3::ForkSafety).to receive(:suppress_warnings!)
    described_class.before_fork
    expect(SQLite3::ForkSafety).to have_received(:suppress_warnings!)
  end

  it "leaves fork safety alone in an sqlite3 too old to have it" do
    allow(SQLite3).to receive(:const_defined?).and_call_original
    allow(SQLite3).to receive(:const_defined?).with(:ForkSafety).and_return(false)
    allow(SQLite3::ForkSafety).to receive(:suppress_warnings!)
    described_class.before_fork
    expect(SQLite3::ForkSafety).not_to have_received(:suppress_warnings!)
  end

  it "takes the pools from Active Record's connection handler" do
    allow(described_class).to receive(:pools).and_call_original
    handler = Struct.new(:connection_pool_list).new([memory])
    stub_const(
      "ActiveRecord::Base",
      Class.new do
        define_singleton_method(:connection_handler) do
          handler
        end
      end
    )
    expect(described_class.pools).to eq([memory])
  end

  it "leaves no file behind" do
    described_class.before_fork
    expect(Dir.glob(File.join(Dir.tmpdir, "mutato-sqlite*"))).to be_empty
  end

  describe "a copy that stops short" do
    let(:backup) { instance_double(SQLite3::Backup, step: 5, remaining: 1, finish: nil) }

    before { allow(SQLite3::Backup).to receive(:new).and_return(backup) }

    it "is refused" do
      expect { described_class.before_fork }
        .to raise_error(RuntimeError, /stopped short/)
    end

    it "is still finished" do
      described_class.before_fork
    rescue RuntimeError
      expect(backup).to have_received(:finish)
    end
  end
end
