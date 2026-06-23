import nibble/lexer
import yum/yaml/node.{type Node}

pub fn from_lexer(span: lexer.Span) -> node.Span {
  let lexer.Span(row_start, col_start, row_end, col_end) = span

  node.Span(
    start: node.Position(row_start, col_start),
    end: node.Position(row_end, col_end),
  )
}

pub fn between(start: lexer.Span, end: lexer.Span) -> node.Span {
  let lexer.Span(row_start:, col_start:, ..) = start
  let lexer.Span(row_end:, col_end:, ..) = end

  node.Span(
    start: node.Position(row_start, col_start),
    end: node.Position(row_end, col_end),
  )
}

pub fn enclosing(first: Node, last: Node) -> node.Span {
  let node.Span(start:, ..) = node.span(first)
  let node.Span(end:, ..) = node.span(last)

  node.Span(start:, end:)
}
