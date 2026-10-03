# frozen_string_literal: true

require "json"

# A frozen-string file with a refinement; spec/mutato/installer_spec.rb reinstalls its methods.
module Shout
  refine String do
    def shout
      "#{upcase}!"
    end
  end
end

using Shout

class Framed
  def label
    "user"
  end

  def loud(word)
    word.shout
  end

  def where
    __FILE__
  end
end
