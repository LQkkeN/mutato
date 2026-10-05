# frozen_string_literal: true

require "tmpdir"

module Mutato
  module Integrations
    # Pools closed before a fork; an in-memory SQLite one, which dies with them, copied over.
    module ActiveRecord
      # :memory:, or a file URI that asks for memory, named or not.
      MEMORY = /\A(?::memory:|file::memory:|file:[^?]*\?(?:[^#]*&)?mode=memory(?:[&#]|\z))/
      private_constant :MEMORY

      module_function

      def before_fork
        memory, others = pools.partition { |pool| memory?(pool) }
        others.each(&:disconnect!)
        @snapshots = renewed(memory)
      end

      def after_fork
        @snapshots.to_a.each { |config, snapshot| restore(config, snapshot) }
      end

      def renewed(memory)
        @snapshots.to_a.each { |_config, snapshot| snapshot.close }
        memory.map { |pool| [pool.pool_config, snapshot(pool)] }
      end

      # In a directory of its own, gone once the read-only handle, which a child keeps, is open.
      def snapshot(pool)
        Dir.mktmpdir("mutato-sqlite") { |dir| opened(pool, File.join(dir, "snapshot.sqlite3")) }
      end

      def opened(pool, path)
        write(pool, path)
        SQLite3::ForkSafety.suppress_warnings! if SQLite3.const_defined?(:ForkSafety)
        SQLite3::Database.new(path, readonly: true)
      end

      def write(pool, path)
        target = SQLite3::Database.new(path)
        pool.with_connection { |connection| copy(connection.raw_connection, target) }
        target.close
      end

      def restore(config, snapshot)
        config.pool.with_connection { |connection| copy(snapshot, connection.raw_connection) }
      end

      # A copy left short, say by a busy database, would leave the child an empty one.
      def copy(from, to)
        backup = SQLite3::Backup.new(to, "main", from, "main")
        backup.step(-1)
        raise "SQLite: the in-memory database copy stopped short" if backup.remaining.nonzero?
      ensure
        backup&.finish
      end

      def pools
        ::ActiveRecord::Base.connection_handler.connection_pool_list
      end

      # Another adapter's ":memory:" is not SQLite's.
      def memory?(pool)
        config = pool.db_config
        config.adapter.to_s.start_with?("sqlite") && config.database.to_s.match?(MEMORY)
      end
    end
  end
end
