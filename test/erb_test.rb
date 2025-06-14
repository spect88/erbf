# frozen_string_literal: true

require "test_helper"

class ErbTest < FormattingTest
  def test_short_block
    assert_formatting_output("<% variable = SomeClass.new %>", "<% variable = SomeClass.new %>")
  end

  def test_longer_block
    assert_formatting_output(<<~INPUT, <<~EXPECTED_OUTPUT)
      <% variable = SomeClass.new(keyword: "argument") %>
    INPUT
      <%
        variable =
          SomeClass.new(keyword: "argument")
      %>
    EXPECTED_OUTPUT
  end

  def test_short_expression
    assert_formatting_output("<%= @variable %>", "<%= @variable %>")
  end

  def test_helper_with_parens
    assert_formatting_output(<<~INPUT, <<~EXPECTED_OUTPUT)
      <%= link_to(t(".somewhere"), somewhere_path(@something), class: "foo") %>
    INPUT
      <%=
        link_to(
          t(".somewhere"),
          somewhere_path(@something),
          class: "foo"
        )
      %>
    EXPECTED_OUTPUT
  end

  def test_helper_without_parens
    assert_formatting_output(<<~INPUT, <<~EXPECTED_OUTPUT)
      <%= link_to t(".somewhere"), somewhere_path(@something), class: "foo" %>
    INPUT
      <%=
        link_to t(".somewhere"),
                somewhere_path(@something),
                class: "foo"
      %>
    EXPECTED_OUTPUT
  end

  def test_short_if
    assert_formatting_output("<% if true %>one<% end %>", "<% if true %>one<% end %>")
  end

  def test_long_if
    assert_formatting_output(<<~INPUT, <<~EXPECTED_OUTPUT)
      <% if some_long_condition && another_condition %>one<% end %>
    INPUT
      <%
        if some_long_condition &&
             another_condition
      %>
        one
      <% end %>
    EXPECTED_OUTPUT
  end

  def test_short_if_else
    assert_formatting_output(<<~INPUT, <<~EXPECTED_OUTPUT)
      <% if true %>one<% else %>two<% end %>
    INPUT
      <% if true %>one<% else %>two<% end %>
    EXPECTED_OUTPUT
  end

  def test_short_unless_else
    assert_formatting_output(<<~INPUT, <<~EXPECTED_OUTPUT)
      <% unless a %>one<% else %>two<% end %>
    INPUT
      <% unless a %>one<% else %>two<% end %>
    EXPECTED_OUTPUT
  end

  def test_long_if_elsif_else
    assert_formatting_output(<<~INPUT, <<~EXPECTED_OUTPUT)
      <% if condition %>one<% elsif another_condition %>two<% else %>three<% end %>
    INPUT
      <% if condition %>
        one
      <% elsif another_condition %>
        two
      <% else %>
        three
      <% end %>
    EXPECTED_OUTPUT
  end

  def test_short_case
    assert_formatting_output(<<~INPUT, <<~EXPECTED_OUTPUT)
      <% case a %><% when 1 %>1<% end %>
    INPUT
      <% case a %><% when 1 %>1<% end %>
    EXPECTED_OUTPUT
  end

  def test_long_case
    assert_formatting_output(<<~INPUT, <<~EXPECTED_OUTPUT)
      <% case a %>
      <%# comment %>
      <% when 1 %>
        1
      <% when 2 %>
        2
      <% else %>
        default
      <% end %>
    INPUT
      <% case a %>
      <%# comment %>
      <% when 1 %>
        1
      <% when 2 %>
        2
      <% else %>
        default
      <% end %>
    EXPECTED_OUTPUT
  end

  def test_case_in
    skip("Herb doesn't support 'case in' yet")
    assert_formatting_output(<<~INPUT, <<~EXPECTED_OUTPUT)
      <% case hash %>
      <% in { a: Integer } %>
        1
      <% in [Integer, Integer]  %>
        2
      <% else %>
        default
      <% end %>
    INPUT
      <% case hash %>
      <% in { a: Integer } %>
        1
      <% in [Integer, Integer]  %>
        2
      <% else %>
        default
      <% end %>
    EXPECTED_OUTPUT
  end

  def test_while
    assert_formatting_output(
      "<% while  condition %>something<% end %>",
      "<% while condition %>something<% end %>"
    )
  end

  def test_until
    assert_formatting_output(
      "<% until  condition %>something<% end %>",
      "<% until condition %>something<% end %>"
    )
  end

  def test_for
    assert_formatting_output(
      "<% for i in 1 .. 5 %>something<% end %>",
      "<% for i in 1..5 %>something<% end %>"
    )
  end

  def test_rescue
    assert_formatting_output(<<~INPUT, <<~EXPECTED_OUTPUT)
      <% begin %>
      <%= dangerous %>
      <% rescue SomeError %>
      <%= fallback %>
      <% end %>
    INPUT
      <% begin %>
        <%= dangerous %>
      <% rescue SomeError %>
        <%= fallback %>
      <% end %>
    EXPECTED_OUTPUT
  end

  def test_rescue_complex
    assert_formatting_output(<<~INPUT, <<~EXPECTED_OUTPUT)
      <% begin %>
      <%= dangerous %>
      <% rescue SomeError %>
      one
      <% rescue AnotherError %>
      two
      <% else %>
      three
      <% ensure %>
      four
      <% end %>
    INPUT
      <% begin %>
        <%= dangerous %>
      <% rescue SomeError %>
        one
      <% rescue AnotherError %>
        two
      <% else %>
        three
      <% ensure %>
        four
      <% end %>
    EXPECTED_OUTPUT
  end

  def test_block_do
    assert_formatting_output(<<~INPUT, <<~EXPECTED_OUTPUT)
      <% 5 .times do %>foo<% end %>
    INPUT
      <% 5.times do %>foo<% end %>
    EXPECTED_OUTPUT
  end

  def test_block_do_args
    assert_formatting_output(<<~INPUT, <<~EXPECTED_OUTPUT)
      <% @a.each  do |(one, two), three| %>
      foo
      <% end %>
    INPUT
      <% @a.each do |(one, two), three| %>
        foo
      <% end %>
    EXPECTED_OUTPUT
  end

  def test_block_curly
    assert_formatting_output(<<~INPUT, <<~EXPECTED_OUTPUT)
      <% 5.times  { %>foo<% } %>
    INPUT
      <% 5.times { %>foo<% } %>
    EXPECTED_OUTPUT
  end

  def test_block_curly_args
    assert_formatting_output(<<~INPUT, <<~EXPECTED_OUTPUT)
      <% @a.each { |(one, two),  three| %>
      foo
      <% } %>
    INPUT
      <% @a.each { |(one, two), three| %>
        foo
      <% } %>
    EXPECTED_OUTPUT
  end

  def test_comment
    assert_formatting_output(<<~INPUT, <<~EXPECTED_OUTPUT)
      <%#
        anything
      %>
    INPUT
      <%#
        anything
      %>
    EXPECTED_OUTPUT
  end
end
