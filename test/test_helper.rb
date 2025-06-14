# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "erbf"

require "minitest/autorun"

class FormattingTest < Minitest::Test
  private

  def assert_formatting_output(input, expected_output)
    erbf = Erbf.new(line_length: 40, debug: !ENV.fetch("DEBUG", "").empty?)
    assert_equal(expected_output.strip, erbf.format_code(input))
  end
end
