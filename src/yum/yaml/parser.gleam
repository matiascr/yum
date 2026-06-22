import gleam/result
import nibble.{type Parser, do, return}
import nibble/lexer
import yum/yaml/ast.{type YamlAST}
import yum/yaml/error.{type YamlError}
import yum/yaml/lexer/context.{type Context}
import yum/yaml/parser/block_collection
import yum/yaml/parser/block_scalar
import yum/yaml/parser/double_quoted
import yum/yaml/parser/flow_collection
import yum/yaml/parser/indentation
import yum/yaml/parser/scalar
import yum/yaml/parser/single_quoted
import yum/yaml/token.{type Token}

pub fn parse(tokens: List(lexer.Token(Token))) -> Result(YamlAST, YamlError) {
  tokens
  |> nibble.run(parser())
  |> result.map_error(error.from_parse_errors)
}

fn parser() -> Parser(YamlAST, Token, Context) {
  use yaml <- do(default_parser())
  use _ <- do(nibble.many(indentation.value_parser()))
  use _ <- do(nibble.eof())

  return(yaml)
}

fn default_parser() -> Parser(YamlAST, Token, Context) {
  nibble.one_of([
    block_collection.parser(),
    block_scalar.parser(),
    flow_collection.parser(),
    double_quoted.parser(),
    single_quoted.parser(),
    scalar.parser(),
  ])
}
