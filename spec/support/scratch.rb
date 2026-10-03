# frozen_string_literal: true

require "fileutils"
require "tmpdir"

# The specs' temporary directories, removed after each example: the self-run runs the
# suite once per mutant, and /tmp can be a tmpfs with few inodes.
module Scratch
  module_function

  def dir
    made = Dir.mktmpdir("mutato-spec")
    made_dirs << made
    made
  end

  def clean
    made_dirs.each { |path| FileUtils.remove_entry(path, true) }
    made_dirs.clear
  end

  def made_dirs
    @made_dirs ||= []
  end
end

RSpec.configure { |config| config.after { Scratch.clean } }
