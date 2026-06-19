import gleam/option.{None}
import nibble.{type Parser, do, return}
import yaml.{type Yaml}
import yaml/lexer/context.{type Context}
import yaml/parser/indentation
import yaml/parser/scalar
import yaml/token.{type Token}

pub fn parser(
  indent: Int,
  value_parser: fn(Int) -> Parser(Yaml, Token, Context),
  // separator_parser: fn(Int) -> Parser(Nil, Token, Context),
) -> Parser(Yaml, Token, Context) {
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
  value_parser: fn(Int) -> Parser(Yaml, Token, Context),
) -> Parser(#(Yaml, Yaml), Token, Context) {
  use key <- do(mapping_key_parser())
  use value <- do(nibble.optional(value_parser(indent)))

  value
  |> option.unwrap(yaml.Null)
  |> pair_with(key)
  |> return
}

fn mapping_key_parser() -> Parser(Yaml, Token, Context) {
  use tok <- nibble.take_map("Expected a block mapping key")
  case tok {
    token.MappingKey(value:) -> scalar.parse(value)
    _ -> None
  }
}

fn pair_with(value: Yaml, key: Yaml) -> #(Yaml, Yaml) {
  #(key, value)
}

fn fail() -> Parser(a, Token, Context) {
  nibble.fail("Expected a block mapping")
}
