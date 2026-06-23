import gleam/list
import gleam/option
import gleam/result
import nibble.{type Parser, do, return}
import yum/yaml/lexer/context.{type Context}
import yum/yaml/node.{type YamlNode}
import yum/yaml/parser/indentation
import yum/yaml/parser/span
import yum/yaml/token.{type Token}

type Entry {
  Entry(value: YamlNode, marker_span: node.Span)
}

pub fn parser(
  indent: Int,
  node_parser: fn(Int) -> Parser(YamlNode, Token, Context),
) -> Parser(YamlNode, Token, Context) {
  use entries <- do(nibble.sequence(
    sequence_entry_parser(indent, node_parser),
    separator: indentation.block_separator_parser(indent),
  ))

  case entries {
    [] -> fail()
    [_, ..] ->
      entries
      |> sequence_node
      |> return
  }
}

fn sequence_entry_parser(
  indent: Int,
  node_parser: fn(Int) -> Parser(YamlNode, Token, Context),
) -> Parser(Entry, Token, Context) {
  use _ <- do(nibble.token(token.Hyphen))
  use marker_span <- do(nibble.span())
  use value <- do(nibble.optional(node_parser(indent)))

  Entry(
    value: value
      |> option.unwrap(null_at(span.from_lexer(marker_span))),
    marker_span: span.from_lexer(marker_span),
  )
  |> return
}

fn sequence_node(entries: List(Entry)) -> YamlNode {
  let values = entries |> list.map(fn(entry) { entry.value })
  let assert [first, ..] = entries
  let last = entries |> list.last() |> result.unwrap(first)

  node.new(
    node.Sequence(values),
    span: entry_span(first, last),
    style: node.BlockSequence,
  )
}

fn entry_span(first: Entry, last: Entry) -> node.Span {
  let node.Span(start:, ..) = first.marker_span
  let node.Span(end:, ..) = node.span(last.value)

  node.Span(start:, end:)
}

fn null_at(span: node.Span) -> YamlNode {
  node.new(node.Null, span:, style: node.Synthetic)
}

fn fail() -> Parser(a, Token, Context) {
  nibble.fail("Expected a block sequence")
}
