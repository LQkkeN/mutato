# frozen_string_literal: true

module Mutato
  Result = Data.define(:status, :outside, :failing, :ran) do
    def outcome
      return { outcome: :caught, detail: "error outside examples", ran: } if outside
      return { outcome: :missed, ran: } if status.zero?

      { outcome: :caught, failing:, ran: }
    end
  end
  public_constant :Result
end
