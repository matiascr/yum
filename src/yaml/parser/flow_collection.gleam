import gleam/option
import nibble.{type Parser, do, return}
import yaml.{type Yaml}
import yaml/lexer/context.{type Context}
import yaml/parser/double_quoted
import yaml/parser/scalar
import yaml/parser/single_quoted
import yaml/token.{type Token}

pub fn sequence_parser() -> Parser(Yaml, Token, Context) {
  use _ <- do(nibble.token(token.OpenSequence))
  use entries <- do(nibble.sequence(
    nibble.optional(sequence_entry_parser()),
    separator: nibble.token(token.Comma),
  ))
  use _ <- do(nibble.optional(nibble.token(token.Comma)))
  use _ <- do(nibble.token(token.CloseSequence))

  entries
  |> option.values()
  |> yaml.Sequence
  |> return
}

pub fn mapping_parser() -> Parser(Yaml, Token, Context) {
  use _ <- do(nibble.token(token.OpenMapping))
  use entries <- do(nibble.sequence(
    nibble.optional(mapping_entry_parser()),
    separator: nibble.token(token.Comma),
  ))
  use _ <- do(nibble.optional(nibble.token(token.Comma)))
  use _ <- do(nibble.token(token.CloseMapping))

  entries
  |> option.values()
  |> yaml.Mapping
  |> return
}

fn sequence_entry_parser() -> Parser(Yaml, Token, Context) {
  nibble.one_of([
    compact_explicit_mapping_parser(),
    compact_empty_key_mapping_parser(),
    compact_plain_mapping_parser(),
    compact_implicit_mapping_or_node_parser(),
  ])
}

fn compact_explicit_mapping_parser() -> Parser(Yaml, Token, Context) {
  use _ <- do(nibble.token(token.QuestionMark))
  use key <- do(flow_node_parser())
  use value <- do(mapping_value_parser())

  yaml.Mapping([#(key, value)])
  |> return
}

fn compact_empty_key_mapping_parser() -> Parser(Yaml, Token, Context) {
  use value <- do(mapping_value_parser())

  yaml.Mapping([#(yaml.Null, value)])
  |> return
}

fn compact_plain_mapping_parser() -> Parser(Yaml, Token, Context) {
  use key <- do(plain_mapping_key_parser())
  use value <- do(
    nibble.one_of([
      flow_node_parser(),
      return(yaml.Null),
    ]),
  )

  yaml.Mapping([#(key, value)])
  |> return
}

fn compact_implicit_mapping_or_node_parser() -> Parser(Yaml, Token, Context) {
  use node <- do(flow_node_parser())
  use value <- do(nibble.optional(mapping_value_parser()))

  case value {
    option.Some(value) -> yaml.Mapping([#(node, value)]) |> return
    option.None -> return(node)
  }
}

fn mapping_entry_parser() -> Parser(#(Yaml, Yaml), Token, Context) {
  nibble.one_of([
    explicit_mapping_entry_parser(),
    implicit_mapping_entry_parser(),
  ])
}

fn explicit_mapping_entry_parser() -> Parser(#(Yaml, Yaml), Token, Context) {
  use _ <- do(nibble.token(token.QuestionMark))

  nibble.one_of([
    implicit_mapping_entry_parser(),
    return(#(yaml.Null, yaml.Null)),
  ])
}

fn implicit_mapping_entry_parser() -> Parser(#(Yaml, Yaml), Token, Context) {
  nibble.one_of([
    plain_mapping_entry_parser(),
    empty_key_mapping_entry_parser(),
    key_mapping_entry_parser(),
  ])
}

fn plain_mapping_entry_parser() -> Parser(#(Yaml, Yaml), Token, Context) {
  use key <- do(plain_mapping_key_parser())
  use value <- do(
    nibble.one_of([
      flow_node_parser(),
      return(yaml.Null),
    ]),
  )

  return(#(key, value))
}

fn empty_key_mapping_entry_parser() -> Parser(#(Yaml, Yaml), Token, Context) {
  use value <- do(mapping_value_parser())

  return(#(yaml.Null, value))
}

fn key_mapping_entry_parser() -> Parser(#(Yaml, Yaml), Token, Context) {
  use key <- do(flow_node_parser())
  use value <- do(
    nibble.one_of([
      mapping_value_parser(),
      return(yaml.Null),
    ]),
  )

  return(#(key, value))
}

fn plain_mapping_key_parser() -> Parser(Yaml, Token, Context) {
  use tok <- nibble.take_map("Expected a plain mapping key")
  case tok {
    token.MappingKey(value:) -> scalar.parse(value)
    _ -> option.None
  }
}

fn mapping_value_parser() -> Parser(Yaml, Token, Context) {
  use _ <- do(nibble.token(token.Colon))

  nibble.one_of([
    flow_node_parser(),
    return(yaml.Null),
  ])
}

fn flow_node_parser() -> Parser(Yaml, Token, Context) {
  nibble.one_of([
    nibble.lazy(sequence_parser),
    nibble.lazy(mapping_parser),
    double_quoted.parser(),
    single_quoted.parser(),
    scalar.parser(),
  ])
}
