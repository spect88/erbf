# frozen_string_literal: true

require "test_helper"

class ErbInHtmlTest < FormattingTest
  def test_long_if_else_inside_inline_tag
    skip("fixme")
    assert_formatting_output(<<~INPUT, <<~EXPECTED_OUTPUT)
      <span><% if condition %>one two three<% else %>four five six<% end %></span>
    INPUT
      <span><%
        if condition
      %>one two three<%
        else
      %>four five six<%
        end
      %></span>
    EXPECTED_OUTPUT
  end

  def test_erb_within_attribute_value
    assert_formatting_output(<<~INPUT, <<~EXPECTED_OUTPUT)
      <div class="<%= classes  %> m-4" ></div>
    INPUT
      <div class="<%= classes %> m-4"></div>
    EXPECTED_OUTPUT
  end

  def test_erb_within_tag
    assert_formatting_output(<<~INPUT, <<~EXPECTED_OUTPUT)
      <div <%= attributes  %> ></div>
    INPUT
      <div <%= attributes %>></div>
    EXPECTED_OUTPUT
  end

  def test_erb_within_tag_name
    skip("Herb doesn't support that")
    assert_formatting_output(<<~INPUT, <<~EXPECTED_OUTPUT)
      <<%= tag_name  %> ></<%= tag_name %>>
    INPUT
      <<%= tag_name  %>></<%= tag_name %>>
    EXPECTED_OUTPUT
  end
end
