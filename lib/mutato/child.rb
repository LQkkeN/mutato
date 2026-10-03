# frozen_string_literal: true

module Mutato
  # `exit!` throughout: a child must not run the parent's at_exit handlers.
  class Child
    CHUNK = 65_536
    private_constant :CHUNK

    def self.run(timeout: nil, log: nil, &)
      new(timeout, log).run(&)
    end

    # Whatever the block raises, the parent gets a result.
    def self.attempt
      yield
    rescue SoftTimeout
      { outcome: :timeout }
    rescue Exception => error
      {
        outcome: :crashed,
        detail: "#{error.class}: #{error.message}",
        backtrace: Array(error.backtrace).first(5)
      }
    end

    # A signal death (segfault, SIGTERM) counts against the mutant until confirmed.
    def self.verdict(data, status)
      return { outcome: :caught, failing: nil, signal: status.termsig } if status.signaled?
      return { outcome: :crashed, detail: "exit status #{status.exitstatus}" } if data.empty?

      Marshal.load(data)
    end

    def initialize(timeout, log)
      @timeout = timeout
      @log = log
      @reader = nil
      @pid = nil
    end

    # Named, not anonymous: Ruby 3.3.0 rejects `&` forwarded from inside a block.
    def run(&block)
      Mutato.config.run_hooks(:before_fork)
      # A project may set default_internal; Marshal's bytes must not be transcoded.
      @reader, writer = IO.pipe(binmode: true)
      @pid = fork { work(writer, &block) }
      collect(writer)
    ensure
      sweep
    end

    private

    # A process group of its own: what the tests start and leave running dies with it.
    def work(writer, &)
      Process.setpgid(0, 0)
      @reader.close
      settle
      deliver(writer, Child.attempt(&))
    end

    # Not the parent's INT/TERM handlers: a mutant that signals itself must end only the child.
    def settle
      %w[INT TERM].each { |signal| trap(signal, "DEFAULT") }
      Mutato.config.run_hooks(:after_fork)
      redirect
    end

    def redirect
      STDIN.reopen(File::NULL)
      log_output if @log
    end

    # The streams, not $stdout: a project's replacement object still writes to them.
    def log_output
      STDOUT.reopen(@log, "w")
      STDERR.reopen(STDOUT)
      STDOUT.sync = true
      $stdout = STDOUT
      $stderr = STDERR
    end

    def deliver(writer, result)
      writer.write(Marshal.dump(result))
    rescue SystemCallError
      # The parent is gone, and there is no one to tell; still no at_exit handlers.
    ensure
      writer.close
      STDOUT.flush
      exit! 0
    end

    def collect(writer)
      writer.close
      data = +""
      status = read_until_exit(data, @timeout && (Clock.now + @timeout))
      status ? Child.verdict(data, status) : killed
    end

    # To the child's exit, not EOF: a process the tests fork holds the pipe. nil past the deadline.
    def read_until_exit(data, deadline)
      loop do
        status = exited
        drain(data)
        return status if status || Clock.left(deadline)&.zero?

        @reader.wait_readable(0.05)
      end
    end

    def exited
      Process.wait2(@pid, Process::WNOHANG)&.last
    end

    def drain(data)
      while (chunk = @reader.read_nonblock(CHUNK, exception: false)).is_a?(String)
        data << chunk
      end
    end

    def killed
      Process.kill("KILL", @pid)
      Process.wait(@pid)
      File.write(@log, "\nmutato: killed after #{@timeout.round(1)} s\n", mode: "a") if @log
      { outcome: :timeout }
    end

    def sweep
      @reader&.close
      Process.kill("KILL", -@pid) if @pid
    rescue Errno::ESRCH, Errno::EPERM
      nil
    end
  end
end
