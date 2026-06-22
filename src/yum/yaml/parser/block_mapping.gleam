import gleam/option.{None}
import nibble.{type Parser, do, return}
import yum/yaml/ast.{type YamlAST} as yaml
import yum/yaml/lexer/context.{type Context}
import yum/yaml/parser/double_quoted
import yum/yaml/parser/flow_collection
import yum/yaml/parser/indentation
import yum/yaml/parser/scalar
import yum/yaml/parser/single_quoted
import yum/yaml/token.{type Token}

pub fn parser(
  indent: Int,
  value_parser: fn(Int) -> Parser(YamlAST, Token, Context),
) -> Parser(YamlAST, Token, Context) {
  use entries <- do(nibble.sequence(
    mapping_entry_parser(indent, value_parser),
    separator: indentation.block_separator_parser(indent),
  ))

  case entries {
    [] -> fail()
    [_, ..] ->
      entries
      |> yaml.Mapping
      |> return
  }
}

fn mapping_entry_parser(
  indent: Int,
  value_parser: fn(Int) -> Parser(YamlAST, Token, Context),
) -> Parser(#(YamlAST, YamlAST), Token, Context) {
  nibble.one_of([
    explicit_mapping_entry_parser(indent, value_parser),
    empty_key_mapping_entry_parser(indent, value_parser),
    implicit_mapping_entry_parser(indent, value_parser),
  ])
}

fn explicit_mapping_entry_parser(
  indent: Int,
  value_parser: fn(Int) -> Parser(YamlAST, Token, Context),
) -> Parser(#(YamlAST, YamlAST), Token, Context) {
  use _ <- do(nibble.token(token.QuestionMark))
  use key <- do(nibble.optional(value_parser(indent)))
  use value <- do(nibble.optional(mapping_value_parser(indent, value_parser)))

  return(#(key |> option.unwrap(yaml.Null), value |> option.unwrap(yaml.Null)))
}

fn empty_key_mapping_entry_parser(
  indent: Int,
  value_parser: fn(Int) -> Parser(YamlAST, Token, Context),
) -> Parser(#(YamlAST, YamlAST), Token, Context) {
  use value <- do(mapping_value_parser(indent, value_parser))

  return(#(yaml.Null, value))
}

fn implicit_mapping_entry_parser(
  indent: Int,
  value_parser: fn(Int) -> Parser(YamlAST, Token, Context),
) -> Parser(#(YamlAST, YamlAST), Token, Context) {
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
  implicit_value_parser: fn(Int) -> Parser(YamlAST, Token, Context),
) -> Parser(#(YamlAST, YamlAST), Token, Context) {
  use key <- do(mapping_key_parser())
  use value <- do(nibble.optional(implicit_value_parser(indent)))

  value
  |> option.unwrap(yaml.Null)
  |> pair_with(key)
  |> return
}

fn implicit_json_mapping_entry_parser(
  indent: Int,
  value_parser: fn(Int) -> Parser(YamlAST, Token, Context),
) -> Parser(#(YamlAST, YamlAST), Token, Context) {
  use key <- do(implicit_json_mapping_key_parser())
  use value <- do(mapping_value_parser(indent, value_parser))

  return(#(key, value))
}

fn implicit_json_mapping_key_parser() -> Parser(YamlAST, Token, Context) {
  nibble.one_of([
    flow_collection.parser(),
    double_quoted.parser(),
    single_quoted.parser(),
  ])
}

fn mapping_value_parser(
  indent: Int,
  value_parser: fn(Int) -> Parser(YamlAST, Token, Context),
) -> Parser(YamlAST, Token, Context) {
  nibble.one_of([
    same_line_mapping_value_parser(indent, value_parser),
    nibble.backtrackable(next_line_mapping_value_parser(indent, value_parser)),
  ])
}

fn same_line_mapping_value_parser(
  indent: Int,
  value_parser: fn(Int) -> Parser(YamlAST, Token, Context),
) -> Parser(YamlAST, Token, Context) {
  use _ <- do(nibble.token(token.Colon))
  use value <- do(nibble.optional(value_parser(indent)))

  value
  |> option.unwrap(yaml.Null)
  |> return
}

fn next_line_mapping_value_parser(
  indent: Int,
  value_parser: fn(Int) -> Parser(YamlAST, Token, Context),
) -> Parser(YamlAST, Token, Context) {
  use Nil <- do(indentation.same_amount_parser(indent))
  same_line_mapping_value_parser(indent, value_parser)
}

fn mapping_key_parser() -> Parser(YamlAST, Token, Context) {
  use tok <- nibble.take_map("Expected a block mapping key")
  case tok {
    token.MappingKey(value:) -> scalar.parse(value)
    _ -> None
  }
}

fn pair_with(value: YamlAST, key: YamlAST) -> #(YamlAST, YamlAST) {
  #(key, value)
}

fn fail() -> Parser(a, Token, Context) {
  nibble.fail("Expected a block mapping")
}
