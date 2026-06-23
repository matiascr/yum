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
//// Use [`parse`](#parse) when you want a single YAML document value. Use
//// [`parse_stream`](#parse_stream) for YAML streams containing zero or more
//// explicit documents. Use [`parse_node`](#parse_node) and
//// [`parse_node_stream`](#parse_node_stream) when you want an opaque node API.
////
//// For tooling-grade loading, parse syntax first and then call
//// [`resolve`](#resolve), or use [`load_node`](#load_node) as the convenience
//// form.
////
//// Use [`parse_document`](#parse_document) when you need document-level
//// metadata such as directives.
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
import yum/yaml/document.{type Document}
import yum/yaml/dynamic as yaml_dynamic
import yum/yaml/emitter
import yum/yaml/error.{type YamlError}
import yum/yaml/lexer
import yum/yaml/node.{type YamlNode}
import yum/yaml/parser
import yum/yaml/resolved.{type Resolved} as resolved_document

pub type DecodeError {
  ParseError(YamlError)
  ResolveError(List(Diagnostic))
  UnableToDecode(List(dynamic_decode.DecodeError))
}

pub type LoadError {
  LoadParseError(YamlError)
  LoadResolveError(List(Diagnostic))
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
  use document <- result.try(parse_document(input))

  document
  |> yaml_from_document
  |> Ok
}

/// Parses a YAML stream into a list of YAML documents.
///
pub fn parse_stream(input: String) -> Result(List(Yaml), YamlError) {
  input
  |> parse_document_stream()
  |> result.map(list.map(_, yaml_from_document))
}

/// Parses a YAML file into a document with node contents and metadata.
///
pub fn parse_document(input: String) -> Result(Document, YamlError) {
  use documents <- result.try(parse_document_stream(input))

  case documents {
    [document] -> Ok(document)
    [_, _, ..] -> Error(error.MultipleDocuments)
    [] -> Error(error.UnexpectedEndOfInput)
  }
}

/// Parses a YAML stream into documents with node contents and metadata.
///
pub fn parse_document_stream(
  input: String,
) -> Result(List(Document), YamlError) {
  use input <- result.try(normalize_whitespace(input, 0))
  use input <- result.try(normalize_indents(input))

  use tokens <- result.try(lexer.lex(input))
  use parsed <- result.try(parser.parse_document_stream(tokens))
  Ok(parsed)
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

  let diagnostics = case resolve(document) {
    Ok(document) -> resolved_document.diagnostics(document)
    Error(diagnostics) -> diagnostics
  }

  Parsed(value: document, diagnostics:)
  |> Ok
}

/// Parses a YAML stream into opaque tooling nodes.
///
pub fn parse_node_stream(input: String) -> Result(List(YamlNode), YamlError) {
  input
  |> parse_document_stream()
  |> result.map(list.map(_, document.root))
}

/// Parses and resolves a YAML document.
///
/// This is the convenience form of `parse_node` followed by `resolve`.
///
pub fn load_node(input: String) -> Result(Resolved, LoadError) {
  use document <- result.try(
    parse_node(input) |> result.map_error(LoadParseError),
  )

  document
  |> resolve()
  |> result.map_error(LoadResolveError)
}

/// Parses and resolves a YAML stream.
///
pub fn load_node_stream(input: String) -> Result(List(Resolved), LoadError) {
  use documents <- result.try(
    parse_node_stream(input) |> result.map_error(LoadParseError),
  )

  documents
  |> list.map(resolve)
  |> result.all()
  |> result.map_error(LoadResolveError)
}

/// Parses a YAML stream into opaque nodes and non-fatal diagnostics.
///
pub fn parse_node_stream_with_diagnostics(
  input: String,
) -> Result(Parsed(List(YamlNode)), YamlError) {
  use documents <- result.try(parse_node_stream(input))

  Parsed(
    value: documents,
    diagnostics: list.flat_map(documents, resolve_diagnostics),
  )
  |> Ok
}

/// Resolves a parsed YAML node into a composed YAML document.
///
/// The syntax parser preserves source structure. This function is the semantic
/// YAML phase: it collects typed diagnostics such as duplicate keys today, and
/// is where anchors, aliases, directives, and tags are validated as support is
/// added.
///
pub fn resolve(node: YamlNode) -> Result(Resolved, List(Diagnostic)) {
  let diagnostics = diagnostic.collect(node)

  case diagnostic.has_errors(diagnostics) {
    True -> Error(diagnostics)
    False -> Ok(resolved_document.new(root: node, diagnostics: diagnostics))
  }
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
  use document <- result.try(
    load_node(input)
    |> result.map_error(fn(error) {
      case error {
        LoadParseError(error) -> ParseError(error)
        LoadResolveError(diagnostics) -> ResolveError(diagnostics)
      }
    }),
  )

  document
  |> resolved_document.root()
  |> to_dynamic()
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

fn resolve_diagnostics(node: YamlNode) -> List(Diagnostic) {
  case resolve(node) {
    Ok(document) -> resolved_document.diagnostics(document)
    Error(diagnostics) -> diagnostics
  }
}

fn yaml_from_document(document: Document) -> Yaml {
  ast.new(
    ast: document.root(document) |> node.to_ast,
    directives: document.directives(document) |> list.map(ast_directive),
  )
}

fn ast_directive(directive: document.Directive) -> ast.YamlDirective {
  let document.Directive(name:, parameters:, ..) = directive

  ast.YamlDirective(name:, parameters:)
}
