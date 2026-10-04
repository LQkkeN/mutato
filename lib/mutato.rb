# frozen_string_literal: true

require_relative "mutato/arid"
require_relative "mutato/change"
require_relative "mutato/config"
require_relative "mutato/emitter"
require_relative "mutato/generation"
require_relative "mutato/generator"
require_relative "mutato/genres"
require_relative "mutato/installer"
require_relative "mutato/mutation"
require_relative "mutato/nodes"
require_relative "mutato/privates"
require_relative "mutato/skips"
require_relative "mutato/subject"
require_relative "mutato/subjects"
require_relative "mutato/usage"
require_relative "mutato/version"
require_relative "mutato/visitor"

module Mutato
  # mutato's own frames, wherever it is installed: its library and its executable.
  FRAMES = %r{\A#{Regexp.escape(__dir__)}/mutato[/.]|(?:\A|/)exe/mutato:}
  public_constant :FRAMES

  def self.config
    @config ||= Config.new
  end

  def self.before_fork(&block)
    config.hooks[:before_fork] << block
  end

  def self.after_fork(&block)
    config.hooks[:after_fork] << block
  end

  def self.after_boot(&block)
    config.hooks[:after_boot] << block
  end

  def self.before_mutant(&block)
    config.hooks[:before_mutant] << block
  end

  def self.skip(pattern, reason)
    config.skip(pattern, reason)
  end

  def self.arid(*names)
    config.arid(*names)
  end

  # A forked child must not share the parent's database sockets.
  before_fork { Sequel::DATABASES.each(&:disconnect) if defined?(Sequel) }
  before_fork do
    ActiveRecord::Base.connection_handler.clear_all_connections! if defined?(ActiveRecord)
  end
end
