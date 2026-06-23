import gleam/list
import gleam/option
import gleam/result
import nibble.{type Parser, do, or, return}
import nibble/lexer
import yum/yaml/document.{type Document}
import yum/yaml/error.{type YamlError}
import yum/yaml/lexer/context.{type Context}
import yum/yaml/node.{type Node}
import yum/yaml/parser/block_collection
import yum/yaml/parser/block_scalar
import yum/yaml/parser/double_quoted
import yum/yaml/parser/flow_collection
import yum/yaml/parser/indentation
import yum/yaml/parser/node_property
import yum/yaml/parser/scalar
import yum/yaml/parser/single_quoted
import yum/yaml/parser/span
import yum/yaml/token.{type Token}

pub fn parse(tokens: List(lexer.Token(Token))) -> Result(Node, YamlError) {
  use documents <- result.try(parse_stream(tokens))

  case documents {
    [document] -> Ok(document)
    [_, _, ..] -> Error(error.MultipleDocuments)
    [] -> Error(error.UnexpectedEndOfInput)
  }
}

pub fn parse_document(
  tokens: List(lexer.Token(Token)),
) -> Result(Document, YamlError) {
  use documents <- result.try(parse_document_stream(tokens))

  case documents {
    [document] -> Ok(document)
    [_, _, ..] -> Error(error.MultipleDocuments)
    [] -> Error(error.UnexpectedEndOfInput)
  }
}

pub fn parse_stream(
  tokens: List(lexer.Token(Token)),
) -> Result(List(Node), YamlError) {
  tokens
  |> parse_document_stream()
  |> result.map(list.map(_, document.root))
}

pub fn parse_document_stream(
  tokens: List(lexer.Token(Token)),
) -> Result(List(Document), YamlError) {
  tokens
  |> nibble.run(stream_parser())
  |> result.map_error(error.from_parse_errors)
}

fn stream_parser() -> Parser(List(Document), Token, Context) {
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

fn stream_document_parser() -> Parser(Document, Token, Context) {
  nibble.one_of([
    explicit_stream_document_parser(),
    nibble.backtrackable(suffixed_stream_document_parser()),
  ])
}

fn explicit_stream_document_parser() -> Parser(Document, Token, Context) {
  use document <- do(explicit_document_parser())
  use _ <- do(indentation_gap_parser())

  return(document)
}

fn suffixed_stream_document_parser() -> Parser(Document, Token, Context) {
  use _ <- do(document_end_parser())
  use _ <- do(indentation_gap_parser())
  use document <- do(document_parser())
  use _ <- do(indentation_gap_parser())

  return(document)
}

fn document_parser() -> Parser(Document, Token, Context) {
  nibble.one_of([
    explicit_document_parser(),
    bare_document_parser(),
  ])
}

fn explicit_document_parser() -> Parser(Document, Token, Context) {
  use directives <- do(nibble.many(directive_line_parser()))
  use _ <- do(indentation_gap_parser())
  use _ <- do(nibble.token(token.DocumentStart))
  use document_start_span <- do(nibble.span())
  use _ <- do(indentation_gap_parser())
  use root <- do(
    default_parser()
    |> or(null_at(span.from_lexer(document_start_span))),
  )

  document.new(root:, directives:)
  |> return
}

fn directive_line_parser() -> Parser(document.Directive, Token, Context) {
  use directive <- do(directive_parser())
  use _ <- do(indentation_gap_parser())

  return(directive)
}

fn bare_document_parser() -> Parser(Document, Token, Context) {
  use root <- do(default_parser())

  document.new(root:, directives: [])
  |> return
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

fn directive_parser() -> Parser(document.Directive, Token, Context) {
  use directive <- do(
    nibble.take_map("Expected a directive", fn(tok) {
      case tok {
        token.Directive(name:, parameters:) -> option.Some(#(name, parameters))
        _ -> option.None
      }
    }),
  )
  use token_span <- do(nibble.span())
  let #(name, parameters) = directive

  document.Directive(name:, parameters:, span: span.from_lexer(token_span))
  |> return
}

fn default_parser() -> Parser(Node, Token, Context) {
  node_property.parser(bare_node_parser())
}

fn bare_node_parser() -> Parser(Node, Token, Context) {
  nibble.one_of([
    block_collection.parser(),
    block_scalar.parser(),
    flow_collection.parser(),
    double_quoted.parser(),
    single_quoted.parser(),
    scalar.parser(),
  ])
}

fn null_at(span: node.Span) -> Node {
  node.new(node.Null, span:, style: node.Synthetic)
}
