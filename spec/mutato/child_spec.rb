# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe Mutato::Child do
  let!(:pid_file) { File.join(Scratch.dir, "pid") }
  let(:alive) do
    lambda do |pid|
      Process.kill(0, pid)
      true
    rescue Errno::ESRCH
      false
    end
  end

  it "returns when the child exits, though a process it forked still holds the pipe" do
    started = Mutato::Clock.now
    result = described_class.run(timeout: 20) { fork { sleep 30 } && { outcome: :missed } }
    expect([result, Mutato::Clock.since(started) < 5]).to eq([{ outcome: :missed }, true])
  end

  it "leaves nothing the child started running" do
    described_class.run { File.write(pid_file, spawn("sleep", "30").to_s) && { outcome: :missed } }
    pid = Integer(File.read(pid_file), 10)
    20.times { sleep 0.05 if alive.call(pid) }
    expect(alive.call(pid)).to be(false)
  end
end
