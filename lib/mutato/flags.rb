# frozen_string_literal: true

require "optparse"

module Mutato
  module Flags
    TABLE = [
      [%w[-h --help], :help, TrueClass],
      [%w[-v --version], :version, TrueClass],
      ["--spec ARGS", :spec, String],
      ["--test ARGS", :test, String],
      ["--config FILE", :config, String],
      ["--diff FILE", :diff, String],
      ["--format NAME", :format, String],
      ["--limit N", :limit, Integer],
      ["--sample N", :sample, Integer],
      ["--genre LIST", :genres, Array],
      ["--only IDS", :only, Array],
      ["--out DIR", :out, String],
      ["--timeout-min S", :timeout_min, Float]
    ].freeze
    DEFAULTS = { out: "mutato.out", timeout_min: 10.0 }.freeze
    GENRES = %w[statement condition relational arithmetic swap-method value element].freeze
    private_constant :TABLE, :DEFAULTS, :GENRES

    module_function

    def parse(argv)
      values = Options.members.to_h { |member| [member, DEFAULTS[member]] }
      parser(values).parse!(argv)
      check(values)
      Options.new(**values)
    end

    # Values OptionParser takes but mutato cannot use, reported the way it reports its own.
    def check(values)
      check_genres(values[:genres].to_a)
      check_frameworks(values)
      negative = %i[limit sample].find { |key| values[key]&.negative? }
      raise OptionParser::InvalidArgument, "--#{negative} #{values[negative]}" if negative
    end

    def check_frameworks(values)
      both = values[:spec] && values[:test]
      raise OptionParser::InvalidArgument, "--spec and --test, one or the other" if both
    end

    def check_genres(genres)
      unknown = genres - GENRES
      wrong = "--genre #{unknown.join(",")} (genres: #{GENRES.join(", ")})"
      raise OptionParser::InvalidArgument, wrong if unknown.any?
    end

    def parser(values)
      parser = OptionParser.new
      TABLE.each { |flag| define(parser, values, flag) }
      parser
    end

    def define(parser, values, flag)
      switches, key, type = flag
      parser.on(*switches, type) { |value| values[key] = value }
    end
  end
end
