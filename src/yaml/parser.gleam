import gleam/option.{None, Some}
import gleam/result
import nibble.{type Parser, do, return}
import nibble/lexer
import yaml.{type Yaml}
import yaml/error.{type YamlError}
import yaml/lexer/context.{type Context}
import yaml/parser/block_sequence
import yaml/parser/double_quoted
import yaml/parser/flow_mapping
import yaml/parser/flow_sequence
import yaml/parser/scalar
import yaml/parser/single_quoted
import yaml/token.{type Token}

pub fn parse(tokens: List(lexer.Token(Token))) -> Result(Yaml, YamlError) {
  tokens
  |> nibble.run(parser())
  |> result.map_error(error.from_parse_errors)
}

fn parser() -> Parser(Yaml, Token, Context) {
  use yaml <- do(default_parser())
  use _ <- do(nibble.many(indentation_parser()))

  return(yaml)
}

fn default_parser() -> Parser(Yaml, Token, Context) {
  nibble.one_of([
    block_sequence.parser(),
    flow_sequence.parser(),
    flow_mapping.parser(),
    double_quoted.parser(),
    single_quoted.parser(),
    scalar.parser(),
  ])
}

fn indentation_parser() -> Parser(Int, Token, Context) {
  use tok <- nibble.take_map("Expected an indentation")
  case tok {
    token.Indentation(indent) -> Some(indent)
    _ -> None
  }
}
