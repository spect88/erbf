# frozen_string_literal: true

require "test_helper"

class HtmlTest < FormattingTest
  def test_long_tag
    assert_formatting_output(<<~INPUT, <<~EXPECTED_OUTPUT)
      <hr id="horizontal_rule_527" class="w-48 border-black" data-controller="horizontal-rule" />
    INPUT
      <hr
        id="horizontal_rule_527"
        class="w-48 border-black"
        data-controller="horizontal-rule"
      />
    EXPECTED_OUTPUT
  end

  def test_self_closing_tag
    assert_formatting_output("<hr>", "<hr />")
  end

  def test_caps
    assert_formatting_output(
      '<HR ID="HR" CLASS="HR" FOO="BAR" />',
      '<hr id="HR" class="HR" FOO="BAR" />'
    )
  end

  def test_no_quotes
    assert_formatting_output("<hr id=horizontal_rule />", '<hr id="horizontal_rule" />')
  end

  def test_apos
    assert_formatting_output(
      '<hr foo=\'no_reason\' bar="&apos;&quot;" baz="&apos;&quot;&quot;" />',
      <<~EXPECTED.strip
        <hr
          foo="no_reason"
          bar="'&quot;"
          baz='&apos;""'
        />
      EXPECTED
    )
  end

  def test_long_text
    assert_formatting_output(
      "<p>Lorem ipsum dolor sit amet, consecteur adipisci tempor incidunt ut labore et dolore</p>",
      <<~EXPECTED_OUTPUT
        <p>
          Lorem ipsum dolor sit amet, consecteur
          adipisci tempor incidunt ut labore et
          dolore
        </p>
      EXPECTED_OUTPUT
    )
  end

  def test_intentional_line_breaks
    assert_formatting_output(<<~INPUT, <<~EXPECTED_OUTPUT)
      <p>One</p>
      <p>Two</p>


      <p>Three</p>
      <p>Four</p>

    INPUT
      <p>One</p>
      <p>Two</p>

      <p>Three</p>
      <p>Four</p>
    EXPECTED_OUTPUT
  end

  def test_complex_block_whitespace
    assert_formatting_output(<<~INPUT, <<~EXPECTED_OUTPUT)
       <div
        class="foo" >


      <p>   Some  Text   </p>
      <p>
        Other  Text
      </p>

      <p>Yet Another Text
      </p>
       </div>

    INPUT
      <div class="foo">
        <p>Some Text</p>
        <p>Other Text</p>

        <p>Yet Another Text</p>
      </div>
    EXPECTED_OUTPUT
  end

  def test_comment
    assert_formatting_output(<<~INPUT, <<~EXPECTED_OUTPUT)
      <!--lorem ipsum dolor sit amet, consectetur adipiscing elit,
          sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.-->
    INPUT
      <!--lorem ipsum dolor sit amet, consectetur adipiscing elit,
          sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.-->
    EXPECTED_OUTPUT
  end

  def test_short_inline_tag
    assert_formatting_output("<span>Lorem ipsum</span>", "<span>Lorem ipsum</span>")
  end

  def test_long_inline_tag
    assert_formatting_output(
      '<span class="foo">Lorem ipsum dolor sit amet</span>',
      <<~EXPECTED_OUTPUT
        <span class="foo"
          >Lorem ipsum dolor sit amet</span
        >
      EXPECTED_OUTPUT
    )
  end

  def test_short_block_tag
    assert_formatting_output("<p>Lorem ipsum</p>", "<p>Lorem ipsum</p>")
  end

  def test_long_block_tag
    assert_formatting_output('<p class="foo">Lorem ipsum dolor sit amet</p>', <<~EXPECTED_OUTPUT)
      <p class="foo">
        Lorem ipsum dolor sit amet
      </p>
    EXPECTED_OUTPUT
  end

  def test_inline_tag
    assert_formatting_output(
      '<span class="foo">Lorem ipsum dolor sit amet</span>',
      <<~EXPECTED_OUTPUT
        <span class="foo"
          >Lorem ipsum dolor sit amet</span
        >
      EXPECTED_OUTPUT
    )
  end

  def test_breaks_between_text_and_inline_tags
    assert_formatting_output("<b>This is bold</b> and <i>this is italic</i>", <<~EXPECTED_OUTPUT)
      <b>This is bold</b> and
      <i>this is italic</i>
    EXPECTED_OUTPUT
  end

  def test_br
    assert_formatting_output("foo<br> bar", "foo<br />\nbar")
  end

  def test_pre
    assert_formatting_output(<<~INPUT, <<~EXPECTED_OUTPUT)
      <pre>
        one
          two
      </pre>
    INPUT
      <pre>
        one
          two
      </pre>
    EXPECTED_OUTPUT
  end
end
