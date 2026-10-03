# frozen_string_literal: true

# Outcome records as mutato writes them, for the specs of what reads them.
module Records
  module_function

  def outcome(outcome, **fields)
    {
      id: "a1b2c3d4e5f6",
      label: "lib/a.rb:3:5: [arithmetic] replace `+` with `-`",
      genre: :arithmetic,
      file: "lib/a.rb",
      line: 3,
      col: 5,
      description: "replace `+` with `-`",
      examples: 1,
      ids: ["./spec/a_spec.rb[1:1]"],
      seconds: 0.5,
      outcome:
    }.merge(fields)
  end
end
