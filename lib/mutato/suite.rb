# frozen_string_literal: true

module Mutato
  Suite = Data.define(:adapter, :baseline, :options, :output)
  public_constant :Suite
end
