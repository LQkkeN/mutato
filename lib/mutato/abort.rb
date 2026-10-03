# frozen_string_literal: true

module Mutato
  class Abort < StandardError
    attr_reader :code

    def initialize(message, code:)
      super(message)
      @code = code
    end
  end
end
