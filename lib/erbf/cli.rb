# frozen_string_literal: true

require "optparse"

class Erbf::CLI
  class Error < StandardError
  end

  def self.call(...)
    new.call(...)
  end

  def initialize
    @command = :format
    @files = []
    @input = nil
    @config_path = nil
  end

  def parse!(argv, stdin)
    argv_left = argv.dup

    begin
      options.parse!(argv_left)
    rescue OptionParser::MissingArgument, OptionParser::InvalidOption => e
      raise Error, e.message
    end

    if @command == :format
      @input = stdin.read if (argv_left.empty? && !stdin.tty?) || argv_left.include?("-")
      argv_left -= ["-"]
    end

    @files =
      argv_left
        .flat_map do |path|
          paths = Dir[path]
          raise Error, "invalid file/directory/glob: #{path}" if paths.empty?

          dirs, files = paths.partition { |p| File.directory?(p) }
          files + dirs.flat_map { |d| Dir["#{d}/**/*.html.erb"] }
        end
        .uniq

    if @input.nil? && @files.empty? && %i[format check write].include?(@command)
      raise Error, "no file/directory/glob specified"
    end
  end

  def execute(stdout = $stdout, stderr = $stderr)
    erbf = Erbf.new(config_file: @config_path)
    case @command
    when :help
      stdout.puts options
      true
    when :version
      stdout.puts Erbf::VERSION
      true
    when :format
      @files.each do |path|
        content = File.read(path)
        stdout.puts erbf.format_code(content)
      end
      stdout.puts erbf.format_code(@input) if @input
      true
    when :check
      success = true
      @files.each do |path|
        original = File.read(path)
        formatted = erbf.format_code(original)
        formatted = "#{formatted}\n"
        next if original == formatted

        stderr.puts "#{path} needs to be formatted"
        success = false
      end
      success
    when :write
      @files.each do |path|
        original = File.read(path)
        formatted = erbf.format_code(original)
        formatted = "#{formatted}\n"
        next if original == formatted

        File.write(path, formatted)
        stdout.puts "Formatted: #{path}"
      end
      true
    end
  end

  def call(argv, stdin, stdout = $stdout, stderr = $stderr)
    parse!(argv, stdin)
    execute(stdout, stderr) ? 0 : 1
  rescue Error => e
    stderr.puts "#{e.message}\n\n"
    stderr.puts options
    1
  end

  def options
    @options ||=
      OptionParser.new do |opts|
        opts.banner = <<~USAGE
          Usage: erbf [options] [files/directories/glob]

          By default the output is written to stdout

          Output options:

        USAGE
        opts.on("-c", "--check", "Check if the files are formatted") do
          raise Error, "incompatible options: --#{@command} and --check" if @command != :format
          @command = :check
        end
        opts.on("-w", "--write", "Format the files in-place") do
          raise Error, "incompatible options: --#{@command} and --write" if @command != :format
          @command = :write
        end
        opts.separator <<~USAGE

          Other options:

        USAGE
        opts.on("--config PATH", String, "Use a config file at a different location") do |path|
          @config_path = path
        end
        opts.on("-h", "--help", "Show this help") do
          raise Error, "incompatible options: --#{@command} and --help" if @command != :format
          @command = :help
        end
        opts.on("-v", "--version", "Show erbf version") do
          raise Error, "incompatible options: --#{@command} and --version" if @command != :format
          @command = :version
        end
        opts.separator ""
      end
  end
end
