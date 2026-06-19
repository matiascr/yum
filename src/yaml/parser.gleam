import gleam/result
import nibble.{type Parser, do, return}
import nibble/lexer
import yaml.{type Yaml}
import yaml/error.{type YamlError}
import yaml/lexer/context.{type Context}
import yaml/parser/block_collection
import yaml/parser/double_quoted
import yaml/parser/flow_collection
import yaml/parser/indentation
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
  use _ <- do(nibble.many(indentation.value_parser()))

  return(yaml)
}

fn default_parser() -> Parser(Yaml, Token, Context) {
  nibble.one_of([
    block_collection.parser(),
    flow_collection.parser(),
    double_quoted.parser(),
    single_quoted.parser(),
    scalar.parser(),
  ])
}
