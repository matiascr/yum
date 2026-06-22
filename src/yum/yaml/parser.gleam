import gleam/option
import gleam/result
import nibble.{type Parser, do, or, return}
import nibble/lexer
import yum/yaml/ast.{type YamlAST} as yaml
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
  use documents <- result.try(parse_stream(tokens))

  case documents {
    [document] -> Ok(document)
    [_, _, ..] -> Error(error.MultipleDocuments)
    [] -> Error(error.UnexpectedEndOfInput)
  }
}

pub fn parse_stream(
  tokens: List(lexer.Token(Token)),
) -> Result(List(YamlAST), YamlError) {
  tokens
  |> nibble.run(stream_parser())
  |> result.map_error(error.from_parse_errors)
}

fn stream_parser() -> Parser(List(YamlAST), Token, Context) {
  use _ <- do(stream_gap_parser())
  use first <- do(nibble.optional(document_parser()))
  use _ <- do(indentation_gap_parser())
  use rest <- do(nibble.many(stream_document_parser()))
  use _ <- do(stream_gap_parser())
  use _ <- do(nibble.eof())

  case first {
    option.Some(document) -> return([document, ..rest])
    option.None -> return(rest)
  }
}

fn stream_document_parser() -> Parser(YamlAST, Token, Context) {
  nibble.one_of([
    explicit_stream_document_parser(),
    nibble.backtrackable(suffixed_stream_document_parser()),
  ])
}

fn explicit_stream_document_parser() -> Parser(YamlAST, Token, Context) {
  use document <- do(explicit_document_parser())
  use _ <- do(indentation_gap_parser())

  return(document)
}

fn suffixed_stream_document_parser() -> Parser(YamlAST, Token, Context) {
  use _ <- do(document_end_parser())
  use _ <- do(indentation_gap_parser())
  use document <- do(document_parser())
  use _ <- do(indentation_gap_parser())

  return(document)
}

fn document_parser() -> Parser(YamlAST, Token, Context) {
  nibble.one_of([
    explicit_document_parser(),
    bare_document_parser(),
  ])
}

fn explicit_document_parser() -> Parser(YamlAST, Token, Context) {
  use _ <- do(nibble.token(token.DocumentStart))
  use _ <- do(indentation_gap_parser())
  use document <- do(default_parser() |> or(yaml.Null))

  return(document)
}

fn bare_document_parser() -> Parser(YamlAST, Token, Context) {
  default_parser()
}

fn stream_gap_parser() -> Parser(Nil, Token, Context) {
  use _ <- do(nibble.many(stream_gap_token_parser()))

  return(Nil)
}

fn indentation_gap_parser() -> Parser(Nil, Token, Context) {
  use _ <- do(nibble.many(indentation_parser()))

  return(Nil)
}

fn stream_gap_token_parser() -> Parser(Nil, Token, Context) {
  nibble.one_of([
    document_end_parser(),
    indentation_parser(),
  ])
}

fn document_end_parser() -> Parser(Nil, Token, Context) {
  use _ <- do(nibble.token(token.DocumentEnd))

  return(Nil)
}

fn indentation_parser() -> Parser(Nil, Token, Context) {
  use _ <- do(indentation.value_parser())

  return(Nil)
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
