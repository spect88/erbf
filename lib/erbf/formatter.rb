# frozen_string_literal: true

class Erbf::Formatter
  autoload :HtmlHelper, "erbf/formatter/html_helper"
  autoload :PrettierPrintHelper, "erbf/formatter/prettier_print_helper"
  autoload :EmbeddedLanguageFormatter, "erbf/formatter/embedded_language_formatter"
  autoload :RubyFormatter, "erbf/formatter/ruby_formatter"

  include HtmlHelper
  include PrettierPrintHelper

  def initialize(q, config)
    @q = q
    @context = []
    @config = config
    @embedded_language = EmbeddedLanguageFormatter.new(config)
    @ruby = RubyFormatter.new(config)
  end

  def visit(node)
    debug { "visiting #{node.class}" }
    node&.accept(self)
  end

  def visit_document_node(node)
    visit_elements(node.children)
  end

  def visit_html_doctype_node(node)
    q.text(node.tag_opening.value.downcase)
    node.children.each(&method(:visit))
    q.text(node.tag_closing.value)
  end

  def visit_html_element_node(node)
    if node.is_void
      debug { "<#{node.open_tag.tag_name.value}> void" }
      q.group do
        visit(node.open_tag)
        q.breakable(" ")
        q.text("/>")
      end
    elsif inline_tag?(node)
      debug { "<#{node.open_tag.tag_name.value}> inline" }
      q.group do
        visit(node.open_tag)
        q.indent do
          q.breakable("")
          q.text(">")
          visit_elements(node.body)
          visit(node.close_tag) if node.close_tag
        end
        if node.close_tag
          q.breakable("")
          q.text(">")
        end
      end
    else
      debug { "<#{node.open_tag.tag_name.value}> block" }
      q.group do
        q.group do
          visit(node.open_tag)
          q.breakable("") if node.body.any?
          q.text(">")
        end
        if node.body.any?
          if pre_tag?(node)
            debug { "pre" }
            q.breakable("", indent: false)
            with_context(:preserve_whitespace) { node.body.each { |child| visit(child) } }
          elsif (language = embedded_language(node))
            debug { "embedded language: #{language}" }
            if @embedded_language.supported?(language) && node.body.size == 1 &&
                 text_node?(node.body.first)
              debug { "formatting" }
              q.indent do
                q.breakable("")
                lines =
                  @embedded_language.format(
                    language,
                    node.body.first.content,
                    [@config.line_length - current_indent_level, 1].max
                  ).lines
                print_formatted_lines(lines)
              end
            else
              debug { "unsupported or more than 1 child node" }
              q.indent do
                q.breakable("")
                with_context(:preserve_whitespace) { node.body.each { |child| visit(child) } }
              end
            end
          else
            debug { "normal block" }
            q.indent do
              q.breakable("")
              visit_elements(node.body)
            end
          end
        end
        if node.close_tag
          q.breakable("") unless pre_tag?(node)
          visit(node.close_tag)
          q.text(">")
        end
      end
    end
  end

  def visit_html_open_tag_node(node)
    q.group do
      q.text("<")
      q.text(node.tag_name.value.downcase)
      if node.children.any?
        q.indent do
          q.breakable(" ")
          q.seplist(node.children, -> { q.breakable(" ") }) { |child| visit(child) }
        end
      end
    end
    # The > is handled in #visit_html_element
  end

  def visit_html_close_tag_node(node)
    q.text("</")
    q.text(node.tag_name.value.downcase)
    # The > is handled in #visit_html_element
  end

  def visit_html_attribute_node(node)
    visit(node.name)
    q.text("=") if node.value
    visit(node.value)
  end

  def visit_html_attribute_name_node(node)
    q.text(case_insensitive_attribute_name?(node) ? node.name.value.downcase : node.name.value)
  end

  def visit_html_attribute_value_node(node)
    if node.children.size == 1 && node.children.first.is_a?(Herb::AST::LiteralNode)
      # The value is a literal, so we can process it to find the optimal way to quote it
      value = node.children.first.content
      quotes_count = value.scan(/"|&quot;|&#34;/i).count
      apostrophes_count = value.scan(/'|&apos;|&#39;/i).count
      if quotes_count > apostrophes_count
        q.text("'")
        q.text(value.gsub(/"|&quot;|&#34/i, '"').gsub(/'|&apos;|&#39;/i, "&apos;"))
        q.text("'")
      else
        q.text('"')
        q.text(value.gsub(/"|&quot;|&#34/i, "&quot;").gsub(/'|&apos;|&#39;/i, "'"))
        q.text('"')
      end
    else
      q.text(node.open_quote.value) if node.quoted
      node.children.each(&method(:visit))
      q.text(node.close_quote.value) if node.quoted
    end
  end

  def visit_literal_node(node)
    q.text(node.content)
  end

  def visit_html_text_node(node)
    if context?(:preserve_whitespace)
      q.group { q.text(node.content) }
      return
    end

    content = node.content.gsub(/\s+/, " ").strip

    q.group do
      content.split.each.with_index do |word, index|
        q.fill_breakable(" ") if index.positive?
        q.text(word)
      end
    end
  end

  def visit_html_comment_node(node)
    q.text("<!--")
    node.children.each(&method(:visit))
    q.text("-->")
  end

  def visit_erb_content_node(node)
    q.text(node.tag_opening.value)

    # Don't format comments
    if node.tag_opening.value == "<%#"
      q.text(node.content.value)
      q.text(node.tag_closing.value)
      return
    end

    q.indent do
      q.breakable(" ")

      lines = format_ruby(node.content.value)
      print_formatted_lines(lines)
    end

    q.breakable(" ")
    q.text(node.tag_closing.value)
  end

  def visit_erb_if_node(node)
    visit_erb_keyword(node) do
      if node.subsequent
        q.breakable("")
        visit(node.subsequent)
      end
    end
  end

  def visit_erb_unless_node(node)
    visit_erb_keyword(node) do
      if node.else_clause
        q.breakable("")
        visit(node.else_clause)
      end
    end
  end

  def visit_erb_case_node(node)
    visit_erb_keyword(node, can_have_statements: false) do
      # "children" are the thing between "case condition" and "when value"
      # Valid values are basically whitespace and ERB comments
      if node.children.any? { |child| !blank_node?(child) }
        q.breakable("")
        visit_elements(node.children)
      end

      if node.conditions.any?
        q.breakable("")
        visit_elements(node.conditions)
      end

      if node.else_clause
        q.breakable("")
        visit(node.else_clause)
      end
    end
  end

  alias visit_erb_case_match_node visit_erb_case_node

  def visit_erb_when_node(node)
    visit_erb_keyword(node, can_have_end: false)
  end

  def visit_erb_in_node(node)
    visit_erb_keyword(node, can_have_end: false)
  end

  def visit_erb_else_node(node)
    q.group do
      q.text(node.tag_opening.value)
      q.breakable(" ")
      q.text(node.content.value.strip)
      q.breakable(" ")
      q.text(node.tag_closing.value)
    end

    if node.statements.any?
      q.indent do
        q.breakable("")
        visit_elements(node.statements)
      end
    end
  end

  def visit_erb_while_node(node)
    visit_erb_keyword(node)
  end

  def visit_erb_until_node(node)
    visit_erb_keyword(node)
  end

  def visit_erb_for_node(node)
    visit_erb_keyword(node)
  end

  def visit_erb_begin_node(node)
    visit_erb_keyword(node) do
      if node.rescue_clause
        q.breakable("")
        visit(node.rescue_clause)
      end

      if node.else_clause
        q.breakable("")
        visit(node.else_clause)
      end

      if node.ensure_clause
        q.breakable("")
        visit(node.ensure_clause)
      end
    end
  end

  def visit_erb_rescue_node(node)
    visit_erb_keyword(node, can_have_end: false) do
      if node.subsequent
        q.breakable("")
        visit(node.subsequent)
      end
    end
  end

  def visit_erb_ensure_node(node)
    visit_erb_keyword(node, can_have_end: false)
  end

  def visit_erb_block_node(node)
    visit_erb_keyword(node, can_have_statements: false) do
      if node.body.any?
        q.indent do
          q.breakable("")
          visit_elements(node.body)
        end
      end
    end
  end

  def visit_erb_end_node(node)
    q.group do
      q.text(node.tag_opening.value)
      q.breakable(" ")
      q.text(node.content.value.strip)
      q.breakable(" ")
      q.text(node.tag_closing.value)
    end
  end

  private

  attr_reader :q

  def visit_erb_keyword(node, can_have_statements: true, can_have_end: true, &block)
    q.group do
      q.text(node.tag_opening.value)

      q.indent do
        q.breakable(" ")

        lines = format_incomplete_ruby(node.content.value)
        print_formatted_lines(lines)
      end

      q.breakable(" ")
      q.text(node.tag_closing.value)
    end

    if can_have_statements && node.statements.any?
      q.indent do
        q.breakable("")
        visit_elements(node.statements)
      end
    end

    block.call if block_given?

    if can_have_end && node.end_node
      q.breakable("")
      visit(node.end_node)
    end
  end

  def visit_elements(children)
    if children.size == 1
      visit(children.first)
      return
    end

    groups =
      children
        .slice_when do |prev_child, next_child|
          ends_with_double_newline?(prev_child) || begins_with_double_newline?(next_child)
        end
        .map do |group|
          group.drop_while(&method(:blank_node?)).reverse.drop_while(&method(:blank_node?)).reverse
        end
        .reject(&:empty?)

    break_next = false

    (groups + [nil]).each_cons(2) do |group, next_group|
      q.group do
        (group + [nil]).each_cons(2) do |child, next_child|
          next if blank_node?(child)

          if break_next
            q.group do
              q.breakable(" ")
              visit(child)
            end
            break_next = false
          else
            visit(child)
          end

          next if next_child.nil?

          if br_tag?(child) && starts_with_whitespace?(next_child)
            debug { "breakable(force) after <br> tag" }
            q.breakable(force: true)
          elsif inline?(child) && inline?(next_child)
            if starts_with_whitespace?(next_child)
              debug { "adding a break before whitespace" }
              q.with_target(q.target.last.contents) { q.breakable(" ") }
            elsif ends_with_whitespace?(child)
              debug { "will add a break after whitespace" }
              break_next = true
            else
              debug { "fill_breakable('') between inline/text without separating whitespace" }
              q.fill_breakable("")
            end
          else
            q.breakable(force: true)
          end
        end
      end
      next if next_group.nil?

      q.breakable(force: true)
      q.breakable(force: true)
    end
  end

  def with_context(context)
    @context.push(context)
    yield
  ensure
    @context.pop
  end

  def context?(value)
    @context.last == value
  end

  def embedded_language(node)
    return nil unless node.is_a?(Herb::AST::HTMLElementNode)

    case node.open_tag.tag_name.value.downcase
    when "script"
      normalize_type(tag_attribute(node, "type"), "text/javascript")
    when "style"
      normalize_type(tag_attribute(node, "type"), "text/css")
    end
  end

  def normalize_type(value, default)
    case value
    when String
      value.downcase
    when :dynamic
      "unknown"
    else
      default
    end
  end

  def format_ruby(code)
    @ruby.format(code, [@config.line_length - current_indent_level, 1].max).lines
  end

  def format_incomplete_ruby(code)
    @ruby.format_incomplete(code, [@config.line_length - current_indent_level, 1].max).lines
  end

  def print_formatted_lines(lines)
    (lines + [nil]).each_cons(2) do |line, next_line|
      break if line.nil?

      q.text(line.chomp)
      q.breakable(force: true) unless next_line.nil?
    end
  end

  def debug(&block)
    @config.logger.debug(self.class.to_s, &block)
  end
end
