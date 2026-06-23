import gleam/list
import gleam/option.{None}
import gleam/result
import nibble.{type Parser, do, return}
import yum/yaml/lexer/context.{type Context}
import yum/yaml/node.{type Node}
import yum/yaml/parser/double_quoted
import yum/yaml/parser/flow_collection
import yum/yaml/parser/indentation
import yum/yaml/parser/scalar
import yum/yaml/parser/single_quoted
import yum/yaml/parser/span
import yum/yaml/token.{type Token}

pub fn parser(
  indent: Int,
  value_parser: fn(Int) -> Parser(Node, Token, Context),
) -> Parser(Node, Token, Context) {
  use entries <- do(nibble.sequence(
    mapping_entry_parser(indent, value_parser),
    separator: indentation.block_separator_parser(indent),
  ))

  case entries {
    [] -> fail()
    [_, ..] ->
      entries
      |> mapping_node
      |> return
  }
}

fn mapping_entry_parser(
  indent: Int,
  value_parser: fn(Int) -> Parser(Node, Token, Context),
) -> Parser(#(Node, Node), Token, Context) {
  nibble.one_of([
    explicit_mapping_entry_parser(indent, value_parser),
    empty_key_mapping_entry_parser(indent, value_parser),
    implicit_mapping_entry_parser(indent, value_parser),
  ])
}

fn explicit_mapping_entry_parser(
  indent: Int,
  value_parser: fn(Int) -> Parser(Node, Token, Context),
) -> Parser(#(Node, Node), Token, Context) {
  use _ <- do(nibble.token(token.QuestionMark))
  use marker_span <- do(nibble.span())
  use key <- do(nibble.optional(value_parser(indent)))
  use value <- do(nibble.optional(mapping_value_parser(indent, value_parser)))
  let default = null_at(span.from_lexer(marker_span))

  return(#(key |> option.unwrap(default), value |> option.unwrap(default)))
}

fn empty_key_mapping_entry_parser(
  indent: Int,
  value_parser: fn(Int) -> Parser(Node, Token, Context),
) -> Parser(#(Node, Node), Token, Context) {
  use value <- do(mapping_value_parser(indent, value_parser))

  return(#(null_at(node.span(value)), value))
}

fn implicit_mapping_entry_parser(
  indent: Int,
  value_parser: fn(Int) -> Parser(Node, Token, Context),
) -> Parser(#(Node, Node), Token, Context) {
  nibble.one_of([
    implicit_plain_mapping_entry_parser(indent, value_parser),
    nibble.backtrackable(implicit_json_mapping_entry_parser(
      indent,
      value_parser,
    )),
  ])
}

fn implicit_plain_mapping_entry_parser(
  indent: Int,
  implicit_value_parser: fn(Int) -> Parser(Node, Token, Context),
) -> Parser(#(Node, Node), Token, Context) {
  use key <- do(mapping_key_parser())
  use value <- do(nibble.optional(implicit_value_parser(indent)))

  value
  |> option.unwrap(null_at(node.span(key)))
  |> pair_with(key)
  |> return
}

fn implicit_json_mapping_entry_parser(
  indent: Int,
  value_parser: fn(Int) -> Parser(Node, Token, Context),
) -> Parser(#(Node, Node), Token, Context) {
  use key <- do(implicit_json_mapping_key_parser())
  use value <- do(mapping_value_parser(indent, value_parser))

  return(#(key, value))
}

fn implicit_json_mapping_key_parser() -> Parser(Node, Token, Context) {
  nibble.one_of([
    flow_collection.parser(),
    double_quoted.parser(),
    single_quoted.parser(),
  ])
}

fn mapping_value_parser(
  indent: Int,
  value_parser: fn(Int) -> Parser(Node, Token, Context),
) -> Parser(Node, Token, Context) {
  nibble.one_of([
    same_line_mapping_value_parser(indent, value_parser),
    nibble.backtrackable(next_line_mapping_value_parser(indent, value_parser)),
  ])
}

fn same_line_mapping_value_parser(
  indent: Int,
  value_parser: fn(Int) -> Parser(Node, Token, Context),
) -> Parser(Node, Token, Context) {
  use _ <- do(nibble.token(token.Colon))
  use colon_span <- do(nibble.span())
  use value <- do(nibble.optional(value_parser(indent)))

  value
  |> option.unwrap(null_at(span.from_lexer(colon_span)))
  |> return
}

fn next_line_mapping_value_parser(
  indent: Int,
  value_parser: fn(Int) -> Parser(Node, Token, Context),
) -> Parser(Node, Token, Context) {
  use Nil <- do(indentation.same_amount_parser(indent))
  same_line_mapping_value_parser(indent, value_parser)
}

fn mapping_key_parser() -> Parser(Node, Token, Context) {
  use kind <- do(
    nibble.take_map("Expected a block mapping key", fn(tok) {
      case tok {
        token.MappingKey(value:) -> scalar.parse(value)
        _ -> None
      }
    }),
  )
  use token_span <- do(nibble.span())

  node.new(kind, span: span.from_lexer(token_span), style: node.PlainScalar)
  |> return
}

fn pair_with(value: Node, key: Node) -> #(Node, Node) {
  #(key, value)
}

fn mapping_node(entries: List(#(Node, Node))) -> Node {
  let assert [first, ..] = entries
  let last = entries |> list.last() |> result.unwrap(first)
  let #(first_key, _) = first
  let #(_, last_value) = last

  node.new(
    node.Mapping(entries),
    span: span.enclosing(first_key, last_value),
    style: node.BlockMapping,
  )
}

fn null_at(span: node.Span) -> Node {
  node.new(node.Null, span:, style: node.Synthetic)
}

fn fail() -> Parser(a, Token, Context) {
  nibble.fail("Expected a block mapping")
}
