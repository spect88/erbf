# frozen_string_literal: true

module Erbf::Formatter::HtmlHelper
  CASE_INSENSITIVE_ATTRIBUTES = %w[id class].to_set.freeze
  INLINE_TAGS = %w[
    a
    abbr
    acronym
    b
    bdo
    big
    br
    button
    cite
    code
    dfn
    em
    i
    img
    input
    kbd
    label
    map
    object
    output
    q
    samp
    select
    small
    span
    strong
    sub
    sup
    textarea
    time
    tt
    var
  ].to_set.freeze

  private

  def inline?(node)
    node.is_a?(Herb::AST::HTMLTextNode) || inline_tag?(node)
  end

  def inline_tag?(node)
    node.is_a?(Herb::AST::HTMLElementNode) &&
      INLINE_TAGS.include?(node.open_tag.tag_name.value.downcase)
  end

  def pre_tag?(node)
    node.is_a?(Herb::AST::HTMLElementNode) && node.open_tag.tag_name.value.downcase == "pre"
  end

  def tag_attribute(node, name)
    attribute =
      node.open_tag.children.find do |child|
        child.is_a?(Herb::AST::HTMLAttributeNode) && child.name.name.value.downcase == name.downcase
      end
    return nil if attribute.nil?

    value_children = attribute.value.children

    if value_children.size == 1 && value_children.first.is_a?(Herb::AST::LiteralNode)
      value_children.first.content
    else
      :dynamic
    end
  end

  def case_insensitive_attribute_name?(node)
    CASE_INSENSITIVE_ATTRIBUTES.include?(node.name.value.downcase)
  end

  def br_tag?(node)
    node.is_a?(Herb::AST::HTMLElementNode) && node.open_tag.tag_name.value.downcase == "br"
  end

  def starts_with_whitespace?(node)
    node.is_a?(Herb::AST::HTMLTextNode) && node.content =~ /\A\s/
  end

  def ends_with_whitespace?(node)
    node.is_a?(Herb::AST::HTMLTextNode) && node.content =~ /\s\z/
  end

  def ends_with_double_newline?(node)
    node.is_a?(Herb::AST::HTMLTextNode) && node.content =~ /\n\s*\n\z/
  end

  def ends_with_newline?(node)
    node.is_a?(Herb::AST::HTMLTextNode) && node.content =~ /\n\z/
  end

  def begins_with_double_newline?(node)
    node.is_a?(Herb::AST::HTMLTextNode) && node.content =~ /\A\n\s*\n/
  end

  def begins_with_newline?(node)
    node.is_a?(Herb::AST::HTMLTextNode) && node.content =~ /\A\n/
  end

  def blank_node?(node)
    node.is_a?(Herb::AST::HTMLTextNode) && node.content =~ /\A\s+\z/
  end

  def text_node?(node)
    node.is_a?(Herb::AST::HTMLTextNode)
  end
end
