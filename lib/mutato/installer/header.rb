# frozen_string_literal: true

require "prism"

module Mutato
  class Installer
    # What a mutant needs from its file: the frozen-string comment and top-level `using`.
    module Header
      module_function

      # The code's second line is the def's; the header goes above the first.
      def evaluate(code, subject)
        path = File.expand_path(subject.file)
        head = of(path)
        source = head + code
        TOPLEVEL_BINDING.eval(source, path, subject.node.location.start_line - 1 - head.count("\n"))
      end

      def of(path)
        result = Prism.parse_file(path)
        "#{frozen_line(result)}#{usings(result)}"
      end

      def frozen_line(result)
        frozen = result.magic_comments.any? { |comment| Header.frozen?(comment) }
        "# frozen_string_literal: true\n" if frozen
      end

      # Ruby accepts dashes and any case in the key and the value.
      def frozen?(comment)
        comment.key.tr("-", "_").casecmp?("frozen_string_literal") && comment.value.casecmp?("true")
      end

      def usings(result)
        calls = result.value.statements.body.select { |node| Nodes.using?(node) }
        calls.sum("") { |node| "#{node.slice}; " }
      end
    end
  end
end
