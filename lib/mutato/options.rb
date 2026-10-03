# frozen_string_literal: true

require "shellwords"

module Mutato
  Options = Data.define(
    :help,
    :version,
    :spec,
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

    def spec_args
      Shellwords.split(spec)
    end

    def genre?(genre)
      genres.nil? || genres.include?(genre.to_s)
    end
  end
  public_constant :Options
end
