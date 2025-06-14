# frozen_string_literal: true

module Erbf::Formatter::PrettierPrintHelper
  private

  def current_indent_level
    queue = [[0, q.groups.first]]
    while (indent, node = queue.shift)
      next_indent = indent

      case node
      when PrettierPrint::Indent
        next_indent += 2
      when PrettierPrint::Align
        next_indent += node.indent
      end

      case node
      when PrettierPrint::Indent, PrettierPrint::Align, PrettierPrint::Group,
           PrettierPrint::LineSuffix
        return indent if node.contents.equal?(q.target)

        queue += node.contents.map { |child| [next_indent, child] }
      when PrettierPrint::IfBreak
        return indent if node.flat_contents.equal?(q.target) || node.break_contents.equal?(q.target)

        queue += (node.flat_contents + node.break_contents).map { |child| [next_indent, child] }
      end
    end

    nil
  end
end
