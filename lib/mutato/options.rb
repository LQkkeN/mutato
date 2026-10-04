# frozen_string_literal: true

require "shellwords"

module Mutato
  Options = Data.define(
    :help,
    :version,
    :spec,
    :test,
    :config,
    :diff,
    :format,
    :limit,
    :sample,
    :genres,
    :only,
    :out,
    :timeout_min
  ) do
    def self.parse(argv)
      Flags.parse(argv)
    end

    # The flag given, else the directory there is: spec for RSpec, test for Minitest.
    def minitest?
      return true if test

      spec.nil? && !Dir.exist?("spec") && Dir.exist?("test")
    end

    def test_args
      Shellwords.split(test || spec || (minitest? ? "test" : "spec"))
    end

    def genre?(genre)
      genres.nil? || genres.include?(genre.to_s)
    end
  end
  public_constant :Options
end
