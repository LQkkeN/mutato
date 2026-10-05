# frozen_string_literal: true

# A connection pool, as far as Mutato::Integrations::ActiveRecord uses one.
class StandInPool
  Config = Struct.new(:adapter, :database)
  Connection = Struct.new(:raw_connection)
  PoolConfig = Struct.new(:pool)
  private_constant :Config, :Connection, :PoolConfig

  attr_reader :db_config, :pool_config, :disconnected

  # config: adapter and database; child: the pool a forked child gets in its place.
  def initialize(config, raw: nil, child: nil)
    @db_config = Config.new(*config)
    @connection = Connection.new(raw)
    @pool_config = PoolConfig.new(child)
    @disconnected = false
  end

  def with_connection
    yield(@connection)
  end

  def disconnect!
    @disconnected = true
  end
end
