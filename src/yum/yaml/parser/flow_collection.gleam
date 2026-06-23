import gleam/list
import gleam/option
import gleam/result
import nibble.{type Parser, do, or, return}
import yum/yaml/lexer/context.{type Context}
import yum/yaml/node.{type YamlNode}
import yum/yaml/parser/double_quoted
import yum/yaml/parser/scalar
import yum/yaml/parser/single_quoted
import yum/yaml/parser/span
import yum/yaml/token.{type Token}

pub fn parser() -> Parser(YamlNode, Token, Context) {
  nibble.lazy(fn() {
    nibble.one_of([
      sequence_parser(),
      mapping_parser(),
    ])
  })
}

fn sequence_parser() -> Parser(YamlNode, Token, Context) {
  use _ <- do(nibble.token(token.OpenSequence))
  use start <- do(nibble.span())
  use entries <- do(comma_separated(sequence_entry_parser()))
  use _ <- do(nibble.optional(nibble.token(token.Comma)))
  use _ <- do(nibble.token(token.CloseSequence))
  use end <- do(nibble.span())

  node.Sequence(entries)
  |> node.new(span: span.between(start, end), style: node.FlowSequence)
  |> return
}

fn mapping_parser() -> Parser(YamlNode, Token, Context) {
  use _ <- do(nibble.token(token.OpenMapping))
  use start <- do(nibble.span())
  use entries <- do(comma_separated(mapping_entry_parser()))
  use _ <- do(nibble.optional(nibble.token(token.Comma)))
  use _ <- do(nibble.token(token.CloseMapping))
  use end <- do(nibble.span())

  node.Mapping(entries)
  |> node.new(span: span.between(start, end), style: node.FlowMapping)
  |> return
}

fn comma_separated(
  parser: Parser(a, Token, Context),
) -> Parser(List(a), Token, Context) {
  {
    use first <- do(parser)
    use rest <- do(nibble.many(comma_then(parser)))
    return([first, ..rest])
  }
  |> or([])
}

fn comma_then(parser: Parser(a, Token, Context)) -> Parser(a, Token, Context) {
  {
    use _ <- do(nibble.token(token.Comma))
    parser
  }
  |> nibble.backtrackable
}

fn sequence_entry_parser() -> Parser(YamlNode, Token, Context) {
  nibble.one_of([
    compact_explicit_mapping_parser(),
    compact_empty_key_mapping_parser(),
    compact_plain_mapping_parser(),
    compact_implicit_mapping_or_node_parser(),
  ])
}

fn compact_explicit_mapping_parser() -> Parser(YamlNode, Token, Context) {
  use _ <- do(nibble.token(token.QuestionMark))
  use marker_span <- do(nibble.span())
  use key <- do(flow_node_parser())
  use value <- do(mapping_value_parser())

  mapping_node([#(key, value)], span.from_lexer(marker_span))
  |> return
}

fn compact_empty_key_mapping_parser() -> Parser(YamlNode, Token, Context) {
  use value <- do(mapping_value_parser())

  mapping_node([#(null_at(node.span(value)), value)], node.span(value))
  |> return
}

fn compact_plain_mapping_parser() -> Parser(YamlNode, Token, Context) {
  use key <- do(plain_mapping_key_parser())
  use value <- do(
    flow_node_parser()
    |> or(null_at(node.span(key))),
  )

  mapping_node([#(key, value)], node.span(key))
  |> return
}

fn compact_implicit_mapping_or_node_parser() -> Parser(YamlNode, Token, Context) {
  use key <- do(flow_node_parser())
  use value <- do(nibble.optional(mapping_value_parser()))

  case value {
    option.Some(value) ->
      mapping_node([#(key, value)], node.span(key)) |> return
    option.None -> return(key)
  }
}

fn mapping_entry_parser() -> Parser(#(YamlNode, YamlNode), Token, Context) {
  nibble.one_of([
    explicit_mapping_entry_parser(),
    implicit_mapping_entry_parser(),
  ])
}

fn explicit_mapping_entry_parser() -> Parser(
  #(YamlNode, YamlNode),
  Token,
  Context,
) {
  use _ <- do(nibble.token(token.QuestionMark))
  use marker_span <- do(nibble.span())

  implicit_mapping_entry_parser()
  |> or(#(
    null_at(span.from_lexer(marker_span)),
    null_at(span.from_lexer(marker_span)),
  ))
}

fn implicit_mapping_entry_parser() -> Parser(
  #(YamlNode, YamlNode),
  Token,
  Context,
) {
  nibble.one_of([
    plain_mapping_entry_parser(),
    empty_key_mapping_entry_parser(),
    key_mapping_entry_parser(),
  ])
}

fn plain_mapping_entry_parser() -> Parser(#(YamlNode, YamlNode), Token, Context) {
  use key <- do(plain_mapping_key_parser())
  use value <- do(
    flow_node_parser()
    |> or(null_at(node.span(key))),
  )

  return(#(key, value))
}

fn empty_key_mapping_entry_parser() -> Parser(
  #(YamlNode, YamlNode),
  Token,
  Context,
) {
  use value <- do(mapping_value_parser())

  return(#(null_at(node.span(value)), value))
}

fn key_mapping_entry_parser() -> Parser(#(YamlNode, YamlNode), Token, Context) {
  use key <- do(flow_node_parser())
  use value <- do(
    mapping_value_parser()
    |> or(null_at(node.span(key))),
  )

  return(#(key, value))
}

fn plain_mapping_key_parser() -> Parser(YamlNode, Token, Context) {
  use kind <- do(
    nibble.take_map("Expected a plain mapping key", fn(tok) {
      case tok {
        token.MappingKey(value:) -> scalar.parse(value)
        _ -> option.None
      }
    }),
  )
  use token_span <- do(nibble.span())

  node.new(kind, span: span.from_lexer(token_span), style: node.PlainScalar)
  |> return
}

fn mapping_value_parser() -> Parser(YamlNode, Token, Context) {
  use _ <- do(nibble.token(token.Colon))
  use colon_span <- do(nibble.span())

  flow_node_parser()
  |> or(null_at(span.from_lexer(colon_span)))
}

fn flow_node_parser() -> Parser(YamlNode, Token, Context) {
  nibble.one_of([
    nibble.lazy(sequence_parser),
    nibble.lazy(mapping_parser),
    double_quoted.parser(),
    single_quoted.parser(),
    scalar.parser(),
  ])
}

fn mapping_node(
  entries: List(#(YamlNode, YamlNode)),
  default_span: node.Span,
) -> YamlNode {
  let mapping_span = case entries {
    [] -> default_span
    [first, ..] -> {
      let last = entries |> list.last() |> result.unwrap(first)
      let #(first_key, _) = first
      let #(_, last_value) = last
      span.enclosing(first_key, last_value)
    }
  }

  node.new(node.Mapping(entries), span: mapping_span, style: node.FlowMapping)
}

fn null_at(span: node.Span) -> YamlNode {
  node.new(node.Null, span:, style: node.Synthetic)
}
