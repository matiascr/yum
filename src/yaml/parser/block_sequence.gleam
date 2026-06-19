import gleam/option
import nibble.{type Parser, do, return}
import yaml.{type Yaml}
import yaml/lexer/context.{type Context}
import yaml/parser/indentation
import yaml/token.{type Token}

pub fn parser(
  indent: Int,
  node_parser: fn(Int) -> Parser(Yaml, Token, Context),
) -> Parser(Yaml, Token, Context) {
  use entries <- do(nibble.sequence(
    sequence_entry_parser(indent, node_parser),
    separator: indentation.block_separator_parser(indent),
  ))

  case entries {
    [] -> fail()
    [_, ..] ->
      entries
      |> yaml.Sequence
      |> return
  }
}

fn sequence_entry_parser(
  indent: Int,
  node_parser: fn(Int) -> Parser(Yaml, Token, Context),
) -> Parser(Yaml, Token, Context) {
  use _ <- do(nibble.token(token.Hyphen))
  use value <- do(nibble.optional(node_parser(indent)))

  value
  |> option.unwrap(yaml.Null)
  |> return
}

fn fail() -> Parser(a, Token, Context) {
  nibble.fail("Expected a block sequence")
}
