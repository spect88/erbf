# frozen_string_literal: true

require "test_helper"

class EmbeddedLanguageTest < FormattingTest
  def test_javascript
    assert_formatting_output(<<~INPUT, <<~EXPECTED_OUTPUT)
      <script>const  foo =  'bar'; let baz = 123;</script>
    INPUT
      <script>
        const foo = "bar";
        let baz = 123;
      </script>
    EXPECTED_OUTPUT
  end

  def test_css
    assert_formatting_output(<<~INPUT, <<~EXPECTED_OUTPUT)
      <style>*{box-sizing:border-box;}</style>
    INPUT
      <style>
        * {
          box-sizing: border-box;
        }
      </style>
    EXPECTED_OUTPUT
  end

  def test_unsupported
    assert_formatting_output(<<~INPUT, <<~EXPECTED_OUTPUT)
      <script type="text/unsupported">const  foo =  'bar'; let baz = 123;</script>
    INPUT
      <script type="text/unsupported">
        const  foo =  'bar'; let baz = 123;
      </script>
    EXPECTED_OUTPUT
  end

  def test_nested_line_length
    # When there is enough space, the line is not broken
    assert_formatting_output(<<~INPUT, <<~EXPECTED_OUTPUT)
      <script>someFunction(app.getSomething(123));</script>
    INPUT
      <script>
        someFunction(app.getSomething(123));
      </script>
    EXPECTED_OUTPUT
    # But when the <script> tag is already nested, the max line length is lower
    assert_formatting_output(<<~INPUT, <<~EXPECTED_OUTPUT)
      <div>
        <div>
          <div>
            <script>someFunction(app.getSomething(123));</script>
          </div>
        </div>
      </div>
    INPUT
      <div>
        <div>
          <div>
            <script>
              someFunction(
                app.getSomething(123),
              );
            </script>
          </div>
        </div>
      </div>
    EXPECTED_OUTPUT
  end
end
