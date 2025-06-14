# frozen_string_literal: true

require "test_helper"
require "tempfile"

class CLITest < Minitest::Test
  def test_help
    exit_code, stdout, stderr = call_cli("--help")
    assert_equal(0, exit_code)
    assert_includes(stdout, "Usage: erbf")
    assert_equal("", stderr)
  end

  def test_version
    exit_code, stdout, stderr = call_cli("--version")
    assert_equal(0, exit_code)
    assert_equal("#{Erbf::VERSION}\n", stdout)
    assert_equal("", stderr)
  end

  def test_invalid_option
    exit_code, stdout, stderr = call_cli("--invalid")
    assert_equal(1, exit_code)
    assert_equal("", stdout)
    assert_includes(stderr, "invalid option: --invalid")
    assert_includes(stderr, "Usage: erbf")
  end

  def test_format_stdin
    exit_code, stdout, stderr = call_cli(stdin: "<div class='foo'></div>")
    assert_equal(0, exit_code)
    assert_equal("<div class=\"foo\"></div>\n", stdout)
    assert_equal("", stderr)
  end

  def test_format_file
    Tempfile.create("erbf_test_format") do |f|
      f.write("<div class='foo'></div>")
      f.flush

      exit_code, stdout, stderr = call_cli(f.path)
      assert_equal(0, exit_code)
      assert_equal("<div class=\"foo\"></div>\n", stdout)
      assert_equal("", stderr)

      f.rewind
      assert_equal("<div class='foo'></div>", f.read)
    end
  end

  def test_check_file
    Tempfile.create("erbf_test_check") do |f|
      f.write("<div class='foo'></div>")
      f.flush

      exit_code, stdout, stderr = call_cli("--check", f.path)
      assert_equal(1, exit_code)
      assert_equal("", stdout)
      assert_equal("#{f.path} needs to be formatted\n", stderr)

      f.rewind
      assert_equal("<div class='foo'></div>", f.read)
    end
  end

  def test_write_file
    Tempfile.create("erbf_test_check") do |f|
      f.write("<div class='foo'></div>")
      f.flush

      exit_code, stdout, stderr = call_cli("--write", f.path)
      assert_equal(0, exit_code)
      assert_equal("Formatted: #{f.path}\n", stdout)
      assert_equal("", stderr)

      f.rewind
      assert_equal("<div class=\"foo\"></div>\n", f.read)
    end
  end

  def test_config
    Tempfile.create("erbf_test_config") do |f|
      f.write("line_length: 10")
      f.flush

      exit_code, stdout, stderr = call_cli("--config", f.path, stdin: "<hr class='lorem ipsum'>")
      assert_equal(0, exit_code)
      assert_equal(<<~EXPECTED_OUTPUT, stdout)
        <hr
          class="lorem ipsum"
        />
      EXPECTED_OUTPUT
      assert_equal("", stderr)
    end
  end

  private

  def call_cli(*argv, stdin: nil)
    stdout = StringIO.new
    stderr = StringIO.new
    stdin = StringIO.new(stdin)
    exit_code = Erbf::CLI.call(argv, stdin, stdout, stderr)
    stdout.rewind
    stderr.rewind
    [exit_code, stdout.read, stderr.read]
  end
end
