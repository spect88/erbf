# frozen_string_literal: true

class Erbf::Formatter::RubyFormatter
  def initialize(config)
    @config = config
    @loaded = false
  end

  def format(code, line_length)
    formatter.call(code, line_length)
  end

  def format_incomplete(code, line_length)
    code = code.strip
    keyword = code[/\A[a-z]+/]
    case keyword
    when "if", "unless", "while", "until", "for", "begin"
      format([code, "end"].join("\n"), line_length).delete_suffix("end").rstrip
    when "elsif"
      format(["if a", code, "end"].join("\n"), line_length)
        .delete_prefix("if a")
        .delete_suffix("end")
        .strip
    when "case"
      format([code, "when true", "end"].join("\n"), line_length)
        .delete_suffix("end")
        .rstrip
        .delete_suffix("when true")
        .rstrip
    when "when", "in"
      format(["case a", code, "end"].join("\n"), line_length)
        .delete_prefix("case a")
        .delete_suffix("end")
        .strip
    when "rescue", "ensure"
      format(["begin", code, "end"].join("\n"), line_length)
        .delete_prefix("begin")
        .delete_suffix("end")
        .strip
    else
      if code =~ /(do|{)\s*(\|[\s,()\w-]+\|)?\z/
        if Regexp.last_match(1) == "{"
          format([code, "}"].join("\n"), line_length).delete_suffix("}").rstrip
        else
          # Formatter may convert short `do end` into `{}`, so let's add content
          format([code, "a" * line_length, "end"].join("\n"), line_length)
            .delete_suffix("end")
            .rstrip
            .delete_suffix("a" * line_length)
            .rstrip
        end
      else
        @config.logger.warn(self.class.to_s) { "Can't handle incomplete ruby: #{code}" }
        code
      end
    end
  end

  private

  def formatter
    @formatter ||=
      case @config.ruby[:formatter]
      when nil
        @config.logger.debug(self.class.to_s) { "Using null formatter" }
        method(:null_format)
      when "syntax_tree"
        begin
          require "syntax_tree"
          (@config.ruby[:syntax_tree_plugins] || []).each do |plugin|
            require "syntax_tree/#{plugin}"
          end
          @config.logger.debug(self.class.to_s) { "Using syntax_tree formatter" }
          method(:syntax_tree_format)
        rescue LoadError => e
          @config.logger.error(self.class.to_s) { e.to_s }
          method(:null_format)
        end
      else
        @config
          .logger
          .error(self.class.to_s) { "Unsupported Ruby formatter: #{@config.ruby[:formatter]}" }
        method(:null_format)
      end
  end

  def null_format(code, _line_length)
    code.strip
  end

  def syntax_tree_format(code, line_length)
    SyntaxTree.format(code, line_length).chomp
  end
end
