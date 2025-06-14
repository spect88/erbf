# frozen_string_literal: true

require "test_helper"

class IntegrationTest < Minitest::Test
  def test_rails_static_404_page
    # This is an HTML page and we're trying to format it exactly the same as prettier
    check_formatting("rails_static_404_page.html")
  end

  private

  def check_formatting(filename)
    formatter = Erbf.new(debug: !ENV.fetch("DEBUG", "").empty?)
    input = File.read("test/fixtures/unformatted/#{filename}")
    actual = formatter.format_code(input)
    expected = File.read("test/fixtures/formatted/#{filename}").chomp
    # When the output is better than what we expected:
    # File.write("test/fixtures/formatted/#{filename}", actual)
    assert_equal(expected, actual)
  end
end
