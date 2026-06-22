import gleam/option
import nibble.{type Parser, do, or, return}
import yum/yaml/ast.{type YamlAST} as yaml
import yum/yaml/lexer/context.{type Context}
import yum/yaml/parser/double_quoted
import yum/yaml/parser/scalar
import yum/yaml/parser/single_quoted
import yum/yaml/token.{type Token}

pub fn parser() -> Parser(YamlAST, Token, Context) {
  nibble.lazy(fn() {
    nibble.one_of([
      sequence_parser(),
      mapping_parser(),
    ])
  })
}

fn sequence_parser() -> Parser(YamlAST, Token, Context) {
  use _ <- do(nibble.token(token.OpenSequence))
  use entries <- do(comma_separated(sequence_entry_parser()))
  use _ <- do(nibble.optional(nibble.token(token.Comma)))
  use _ <- do(nibble.token(token.CloseSequence))

  entries
  |> yaml.Sequence
  |> return
}

fn mapping_parser() -> Parser(YamlAST, Token, Context) {
  use _ <- do(nibble.token(token.OpenMapping))
  use entries <- do(comma_separated(mapping_entry_parser()))
  use _ <- do(nibble.optional(nibble.token(token.Comma)))
  use _ <- do(nibble.token(token.CloseMapping))

  entries
  |> yaml.Mapping
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

fn sequence_entry_parser() -> Parser(YamlAST, Token, Context) {
  nibble.one_of([
    compact_explicit_mapping_parser(),
    compact_empty_key_mapping_parser(),
    compact_plain_mapping_parser(),
    compact_implicit_mapping_or_node_parser(),
  ])
}

fn compact_explicit_mapping_parser() -> Parser(YamlAST, Token, Context) {
  use _ <- do(nibble.token(token.QuestionMark))
  use key <- do(flow_node_parser())
  use value <- do(mapping_value_parser())

  yaml.Mapping([#(key, value)])
  |> return
}

fn compact_empty_key_mapping_parser() -> Parser(YamlAST, Token, Context) {
  use value <- do(mapping_value_parser())

  yaml.Mapping([#(yaml.Null, value)])
  |> return
}

fn compact_plain_mapping_parser() -> Parser(YamlAST, Token, Context) {
  use key <- do(plain_mapping_key_parser())
  use value <- do(
    flow_node_parser()
    |> or(yaml.Null),
  )

  yaml.Mapping([#(key, value)])
  |> return
}

fn compact_implicit_mapping_or_node_parser() -> Parser(YamlAST, Token, Context) {
  use node <- do(flow_node_parser())
  use value <- do(nibble.optional(mapping_value_parser()))

  case value {
    option.Some(value) -> yaml.Mapping([#(node, value)]) |> return
    option.None -> return(node)
  }
}

fn mapping_entry_parser() -> Parser(#(YamlAST, YamlAST), Token, Context) {
  nibble.one_of([
    explicit_mapping_entry_parser(),
    implicit_mapping_entry_parser(),
  ])
}

fn explicit_mapping_entry_parser() -> Parser(
  #(YamlAST, YamlAST),
  Token,
  Context,
) {
  use _ <- do(nibble.token(token.QuestionMark))

  implicit_mapping_entry_parser()
  |> or(#(yaml.Null, yaml.Null))
}

fn implicit_mapping_entry_parser() -> Parser(
  #(YamlAST, YamlAST),
  Token,
  Context,
) {
  nibble.one_of([
    plain_mapping_entry_parser(),
    empty_key_mapping_entry_parser(),
    key_mapping_entry_parser(),
  ])
}

fn plain_mapping_entry_parser() -> Parser(#(YamlAST, YamlAST), Token, Context) {
  use key <- do(plain_mapping_key_parser())
  use value <- do(
    flow_node_parser()
    |> or(yaml.Null),
  )

  return(#(key, value))
}

fn empty_key_mapping_entry_parser() -> Parser(
  #(YamlAST, YamlAST),
  Token,
  Context,
) {
  use value <- do(mapping_value_parser())

  return(#(yaml.Null, value))
}

fn key_mapping_entry_parser() -> Parser(#(YamlAST, YamlAST), Token, Context) {
  use key <- do(flow_node_parser())
  use value <- do(
    mapping_value_parser()
    |> or(yaml.Null),
  )

  return(#(key, value))
}

fn plain_mapping_key_parser() -> Parser(YamlAST, Token, Context) {
  use tok <- nibble.take_map("Expected a plain mapping key")
  case tok {
    token.MappingKey(value:) -> scalar.parse(value)
    _ -> option.None
  }
}

fn mapping_value_parser() -> Parser(YamlAST, Token, Context) {
  use _ <- do(nibble.token(token.Colon))

  flow_node_parser()
  |> or(yaml.Null)
}

fn flow_node_parser() -> Parser(YamlAST, Token, Context) {
  nibble.one_of([
    nibble.lazy(sequence_parser),
    nibble.lazy(mapping_parser),
    double_quoted.parser(),
    single_quoted.parser(),
    scalar.parser(),
  ])
}
