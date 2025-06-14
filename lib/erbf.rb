# frozen_string_literal: true

require "herb"
require "prettier_print"
require "pp"

class Erbf
  autoload :Config, "erbf/config"
  autoload :Formatter, "erbf/formatter"
  autoload :CLI, "erbf/cli"
  autoload :VERSION, "erbf/version"

  def initialize(config_or_options = {})
    @config =
      (config_or_options.is_a?(Config) ? config_or_options : Config.load(**config_or_options))
    @logger = @config.logger
    @logger.debug! if @config.debug?
  end

  def format_code(input)
    result = Herb.parse(input)
    # TODO: Handle errors
    format_ast(result.value)
  end

  def format_ast(ast_node)
    PrettierPrint.format(+"", @config.line_length) do |q|
      @logger.debug(to_s) { "AST:\n#{PP.pp(ast_node, +"", 80)}" }
      # TODO: Use Herb::Visitor
      Formatter.new(q, @config).visit(ast_node)
      @logger.debug(to_s) { "Formatted:\n#{PP.pp(q.target, +"", 80)}" }
    end
  end
end
