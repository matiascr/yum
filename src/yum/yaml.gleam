//// YAML parsing.
////
//// This is the main public module for parsing YAML documents:
////
//// ```gleam
//// import yum/yaml
////
//// yaml.parse("name: yum")
//// ```
////
//// Use [`parse`](#parse) when you want a single YAML document value, including
//// document-level metadata such as directives. Use [`parse_stream`](#parse_stream) for
//// YAML streams containing zero or more explicit documents. Use [`parse_node`](#parse_node)
//// and [`parse_node_stream`](#parse_node_stream) when you want an opaque node API.
////

import gleam/bool
import gleam/dynamic.{type Dynamic}
import gleam/dynamic/decode as dynamic_decode
import gleam/int
import gleam/list
import gleam/result
import gleam/string
import yum/yaml/ast.{type Yaml, type YamlAST}
import yum/yaml/diagnostic.{type Diagnostic}
import yum/yaml/dynamic as yaml_dynamic
import yum/yaml/emitter
import yum/yaml/error.{type YamlError}
import yum/yaml/lexer
import yum/yaml/node.{type YamlNode}
import yum/yaml/parser

pub type DecodeError {
  ParseError(YamlError)
  UnableToDecode(List(dynamic_decode.DecodeError))
}

/// A parsed value with non-fatal diagnostics collected from it.
///
pub type Parsed(a) {
  Parsed(value: a, diagnostics: List(Diagnostic))
}

/// Parses a YAML file into a YAML document.
///
/// Follows the [YAML 1.2 specification](https://yaml.org/spec/1.2.2/)
///
pub fn parse(input: String) -> Result(Yaml, YamlError) {
  input
  |> parse_ast()
  |> result.map(ast.to_yaml)
}

/// Parses a YAML stream into a list of YAML documents.
///
pub fn parse_stream(input: String) -> Result(List(Yaml), YamlError) {
  input
  |> parse_ast_stream()
  |> result.map(list.map(_, ast.to_yaml))
}

/// Parses a YAML file into the AST node for its document contents.
///
pub fn parse_ast(input: String) -> Result(YamlAST, YamlError) {
  use documents <- result.try(parse_ast_stream(input))

  case documents {
    [document] -> Ok(document)
    [_, _, ..] -> Error(error.MultipleDocuments)
    [] -> Error(error.UnexpectedEndOfInput)
  }
}

/// Parses a YAML stream into the AST nodes for each document's contents.
///
pub fn parse_ast_stream(input: String) -> Result(List(YamlAST), YamlError) {
  input
  |> parse_node_stream()
  |> result.map(list.map(_, node.to_ast))
}

/// Parses a YAML file into an opaque tooling node for its document contents.
///
pub fn parse_node(input: String) -> Result(YamlNode, YamlError) {
  use documents <- result.try(parse_node_stream(input))

  case documents {
    [document] -> Ok(document)
    [_, _, ..] -> Error(error.MultipleDocuments)
    [] -> Error(error.UnexpectedEndOfInput)
  }
}

/// Parses a YAML file into an opaque node and non-fatal diagnostics.
///
pub fn parse_node_with_diagnostics(
  input: String,
) -> Result(Parsed(YamlNode), YamlError) {
  use document <- result.try(parse_node(input))

  Parsed(value: document, diagnostics: diagnostic.collect(document))
  |> Ok
}

/// Parses a YAML stream into opaque tooling nodes.
///
pub fn parse_node_stream(input: String) -> Result(List(YamlNode), YamlError) {
  use input <- result.try(normalize_whitespace(input, 0))
  use input <- result.try(normalize_indents(input))

  use tokens <- result.try(lexer.lex(input))
  use parsed <- result.try(parser.parse_stream(tokens))
  Ok(parsed)
}

/// Parses a YAML stream into opaque nodes and non-fatal diagnostics.
///
pub fn parse_node_stream_with_diagnostics(
  input: String,
) -> Result(Parsed(List(YamlNode)), YamlError) {
  use documents <- result.try(parse_node_stream(input))

  Parsed(
    value: documents,
    diagnostics: list.flat_map(documents, diagnostic.collect),
  )
  |> Ok
}

/// Converts a span-aware YAML node to Gleam dynamic data for use with decoders.
///
pub fn to_dynamic(node: YamlNode) -> Dynamic {
  yaml_dynamic.from_node(node)
}

/// Converts a simple YAML AST value to Gleam dynamic data for use with decoders.
///
pub fn ast_to_dynamic(ast: YamlAST) -> Dynamic {
  yaml_dynamic.from_ast(ast)
}

/// Parses YAML and decodes it using a `gleam/dynamic/decode` decoder.
///
pub fn decode(
  from input: String,
  using decoder: dynamic_decode.Decoder(t),
) -> Result(t, DecodeError) {
  use node <- result.try(parse_node(input) |> result.map_error(ParseError))

  node
  |> to_dynamic
  |> dynamic_decode.run(decoder)
  |> result.map_error(UnableToDecode)
}

/// Emits a deterministic YAML string from a YAML node and validates the output.
///
pub fn to_string(node: YamlNode) -> Result(String, YamlError) {
  let rendered = emitter.to_string(node)
  use _ <- result.try(parse_ast(rendered))
  Ok(rendered)
}

/// Normalizes whitespace in the YAML file.
/// By default, turns every un-escaped tab (`\t`) into the given amount of
/// whitespaces.
///
fn normalize_whitespace(
  input: String,
  tab_equivalent: Int,
) -> Result(String, YamlError) {
  use <- bool.guard(when: tab_equivalent == 0, return: Ok(input))
  input
  |> string.replace(each: "\t", with: string.repeat(" ", tab_equivalent))
  |> Ok
}

/// Normalizes the indentation of the YAML file.
/// If all lines have <X leading whitespace, all lines will be trimmed X spaces
/// going forward.
///
fn normalize_indents(input: String) -> Result(String, YamlError) {
  let lines = string.split(input, "\n")
  use x <- result.try(find_min_indent(lines))
  let min_indent = int.absolute_value(x)

  lines
  |> list.map(string.drop_start(_, min_indent))
  |> string.join("\n")
  |> Ok
}

fn find_min_indent(lines: List(String)) -> Result(Int, YamlError) {
  lines
  |> list.map(count_indents)
  |> list.map(int.negate)
  |> list.max(int.compare)
  |> result.replace_error(error.IndentNormalizationError)
}

fn count_indents(input: String) -> Int {
  case input {
    " " <> rest -> 1 + count_indents(rest)
    _ -> 0
  }
}
