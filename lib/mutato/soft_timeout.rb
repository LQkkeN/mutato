# frozen_string_literal: true

module Mutato
  # Not a StandardError: a worker loop's `rescue => e` would swallow it.
  class SoftTimeout < Exception
  end
  public_constant :SoftTimeout
end
