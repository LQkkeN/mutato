# frozen_string_literal: true

require "prism"

module Mutato
  class Subjects
    # foreign: inside `class << obj` for an obj other than self.
    Scope = Data.define(:chain, :in_block, :foreign) do
      def self.top
        new(chain: [], in_block: false, foreign: false)
      end

      def into(node)
        case node
        when Prism::ModuleNode, Prism::ClassNode then nest(
          KINDS.fetch(node.class),
          node.constant_path.slice
        )
        when Prism::SingletonClassNode then singleton(node)
        else Nodes.one_of?(node, Nodes::BLOCKS) ? with(in_block: true) : self
        end
      end

      def singleton(node)
        node.expression.is_a?(Prism::SelfNode) ? nest(:sclass, nil) : with(foreign: true)
      end

      def nest(kind, name)
        with(chain: chain + [[kind, name]])
      end

      def singleton_class?
        chain.last == [:sclass, nil]
      end

      # Whether `name` is the enclosing class, as `More` in `def More.x` inside `class More`.
      def enclosing?(name)
        _, enclosing = chain.last
        enclosing.to_s.split("::").last == name
      end
    end
    private_constant :Scope
  end
end
