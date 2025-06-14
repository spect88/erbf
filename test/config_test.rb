# frozen_string_literal: true

require "test_helper"
require "logger"

class ConfigTest < Minitest::Test
  def test_default
    config = Erbf::Config.load
    assert_equal(80, config.line_length)
    assert_instance_of(Logger, config.logger)
    assert_equal(false, config.debug?)
    assert_equal(3, config.embedded.size)
    assert_equal("syntax_tree", config.ruby[:formatter])
  end

  def test_keyword_override
    custom_logger = Class.new(Logger)
    config =
      Erbf::Config.load(
        line_length: 70,
        logger: custom_logger.new(StringIO.new),
        debug: true,
        embedded: [],
        ruby: {
          formatter: nil
        }
      )
    assert_equal(70, config.line_length)
    assert_instance_of(custom_logger, config.logger)
    assert_equal(true, config.debug?)
    assert_equal(0, config.embedded.size)
    assert_nil(config.ruby[:formatter])
  end

  def test_yaml
    Tempfile.create("erbf_test_config") do |f|
      f.write(<<~YAML)
        ---
        line_length: 70

        # Format CSS using a custom 'css-formatter' command
        embedded:
          - types:
            - text/css
            command: css-formatter --line-length %<line_length>d

        # Don't format Ruby code
        ruby:
          formatter: null
      YAML
      f.flush

      config = Erbf::Config.load(config_file: f.path)

      assert_equal(70, config.line_length)
      assert_instance_of(Logger, config.logger)
      assert_equal(false, config.debug?)
      assert_equal(1, config.embedded.size)
      assert_nil(config.ruby[:formatter])
    end
  end

  def test_combination_of_all
    Tempfile.create("erbf_test_config") do |f|
      f.write(<<~YAML)
        ---
        line_length: 70
        ruby:
          formatter: null
      YAML
      f.flush

      config = Erbf::Config.load(config_file: f.path, line_length: 60, debug: true)

      assert_equal(60, config.line_length)
      assert_instance_of(Logger, config.logger)
      assert_equal(true, config.debug?)
      assert_equal(3, config.embedded.size)
      assert_nil(config.ruby[:formatter])
    end
  end
end
