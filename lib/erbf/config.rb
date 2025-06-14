# frozen_string_literal: true

require "logger"
require "yaml"

class Erbf::Config
  DEFAULT_FILEPATHS = %w[config/erbf.yml .erbf.yml].freeze

  attr_reader :line_length, :logger, :embedded, :ruby

  def initialize(line_length:, logger:, debug:, embedded:, ruby:)
    @line_length = line_length
    @logger = logger
    @debug = debug
    @embedded = embedded
    @ruby = ruby
  end

  def debug? = @debug

  class << self
    def load(config_file: nil, **options)
      opts =
        default_options.merge(
          config_file.nil? ? options_from_default_file : options_from_file(config_file),
          options
        )
      new(**opts)
    end

    def default_embedded
      prettier = "node_modules/.bin/prettier"
      if File.exist?(prettier)
        [
          {
            types: %w[text/javascript module],
            command: "#{prettier} --stdin-filepath file.js --print-width %<line_length>d"
          },
          {
            types: ["text/css"],
            command: "#{prettier} --stdin-filepath file.css --print-width %<line_length>d"
          },
          {
            types: %w[importmap application/json application/ld+json],
            command: "#{prettier} --stdin-filepath file.json --print-width %<line_length>d"
          }
        ]
      else
        []
      end
    end

    def default_ruby
      { formatter: "syntax_tree", syntax_tree_plugins: [] }
    end

    def default_options
      {
        line_length: 80,
        logger: Logger.new($stderr, level: Logger::WARN),
        debug: false,
        embedded: default_embedded,
        ruby: default_ruby
      }
    end

    def options_from_file(path)
      yaml = YAML.safe_load_file(path, symbolize_names: true)
      { line_length: yaml[:line_length], embedded: yaml[:embedded], ruby: yaml[:ruby] }.compact
    end

    def options_from_default_file
      DEFAULT_FILEPATHS.each do |path|
        next unless File.exist?(path)

        return options_from_file(path)
      end
      {}
    end
  end
end
