# frozen_string_literal: true

module Mutato
  class Visitor
    Walk = Struct.new(:cursor, :deleted, :spared, :dead) do
      def self.start
        new(Cursor.start, identity_set, identity_set, identity_set)
      end

      # Nodes compare by structure; the walk needs the very node.
      def self.identity_set
        Set.new.compare_by_identity
      end
    end
    private_constant :Walk
  end
end
