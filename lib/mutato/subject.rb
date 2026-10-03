# frozen_string_literal: true

module Mutato
  Subject = Data.define(:file, :name, :chain, :node, :singleton, :receiver, :skip, :block_lines) do
    # The constant that owns the method, `App::Calc`; empty at the top level.
    def owner_name
      receiver || chain.filter_map(&:last).join("::")
    end

    def qualified
      "#{owner_name}#{singleton ? "." : "#"}#{name}"
    end

    alias_method :to_s, :qualified

    def skipped_line
      "skipped #{qualified}: #{skip}  #{file}:#{node.location.start_line}"
    end
  end
  public_constant :Subject
end
