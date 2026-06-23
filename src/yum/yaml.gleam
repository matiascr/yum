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
//// [`resolve`](#resolve) or [`resolve_document`](#resolve_document), or use
//// [`load_node`](#load_node) as the convenience form.
////
//// Use [`parse_document`](#parse_document) when you need document-level
//// metadata such as directives.
////

import gleam/bool
import gleam/dict.{type Dict}
import gleam/dynamic.{type Dynamic}
import gleam/dynamic/decode as dynamic_decode
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
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
  use document <- result.try(parse_document(input))
  let root = document.root(document)

  let diagnostics = case resolve_document(document) {
    Ok(document) -> resolved_document.diagnostics(document)
    Error(diagnostics) -> diagnostics
  }

  Parsed(value: root, diagnostics:)
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
/// This is the convenience form of `parse_document` followed by
/// `resolve_document`, so document-level directives are available during
/// resolution.
///
pub fn load_node(input: String) -> Result(Resolved, LoadError) {
  use document <- result.try(
    parse_document(input) |> result.map_error(LoadParseError),
  )

  document
  |> resolve_document()
  |> result.map_error(LoadResolveError)
}

/// Parses and resolves a YAML stream.
///
pub fn load_node_stream(input: String) -> Result(List(Resolved), LoadError) {
  use documents <- result.try(
    parse_document_stream(input) |> result.map_error(LoadParseError),
  )

  documents
  |> list.map(resolve_document)
  |> result.all()
  |> result.map_error(LoadResolveError)
}

/// Parses a YAML stream into opaque nodes and non-fatal diagnostics.
///
pub fn parse_node_stream_with_diagnostics(
  input: String,
) -> Result(Parsed(List(YamlNode)), YamlError) {
  use documents <- result.try(parse_document_stream(input))
  let roots = list.map(documents, document.root)

  Parsed(
    value: roots,
    diagnostics: list.flat_map(documents, resolve_document_diagnostics),
  )
  |> Ok
}

/// Resolves a parsed YAML node into a composed YAML document.
///
/// The syntax parser preserves source structure. This function is the semantic
/// YAML phase for node-only callers. It collects typed diagnostics such as
/// duplicate keys and unknown aliases, and validates tags using the default tag
/// handles.
///
pub fn resolve(node: YamlNode) -> Result(Resolved, List(Diagnostic)) {
  document.new(root: node, directives: [])
  |> resolve_document()
}

/// Resolves a parsed YAML document into a composed YAML document.
///
/// This is the document-aware semantic phase. It validates directives,
/// expands tag handles, and collects typed diagnostics such as duplicate keys
/// and unknown aliases.
///
pub fn resolve_document(
  document: Document,
) -> Result(Resolved, List(Diagnostic)) {
  let #(tag_handles, directive_diagnostics) =
    document
    |> document.directives()
    |> tag_handles()

  let #(root, tag_diagnostics) =
    document
    |> document.root()
    |> resolve_node_tags(tag_handles)

  let diagnostics =
    []
    |> list.append(directive_diagnostics)
    |> list.append(tag_diagnostics)
    |> list.append(diagnostic.collect(root))

  case diagnostic.has_errors(diagnostics) {
    True -> Error(diagnostics)
    False -> Ok(resolved_document.new(root: root, diagnostics: diagnostics))
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

fn resolve_document_diagnostics(document: Document) -> List(Diagnostic) {
  case resolve_document(document) {
    Ok(document) -> resolved_document.diagnostics(document)
    Error(diagnostics) -> diagnostics
  }
}

fn tag_handles(
  directives: List(document.Directive),
) -> #(Dict(String, String), List(Diagnostic)) {
  list.fold(directives, #(default_tag_handles(), []), fn(acc, directive) {
    let #(handles, diagnostics) = acc

    case directive {
      document.Directive(name: "TAG", parameters: [handle, prefix], span:) ->
        case valid_tag_handle(handle) {
          True -> #(dict.insert(handles, handle, prefix), diagnostics)
          False -> #(
            handles,
            list.append(diagnostics, [diagnostic.InvalidTagDirective(span:)]),
          )
        }

      document.Directive(name: "TAG", span:, ..) -> #(
        handles,
        list.append(diagnostics, [diagnostic.InvalidTagDirective(span:)]),
      )

      _ -> acc
    }
  })
}

fn default_tag_handles() -> Dict(String, String) {
  dict.new()
  |> dict.insert("!", "!")
  |> dict.insert("!!", "tag:yaml.org,2002:")
}

fn valid_tag_handle(handle: String) -> Bool {
  case handle {
    "!" | "!!" -> True
    "!" <> rest -> string.ends_with(rest, "!") && string.length(rest) > 1
    _ -> False
  }
}

fn resolve_node_tags(
  value: YamlNode,
  handles: Dict(String, String),
) -> #(YamlNode, List(Diagnostic)) {
  let #(kind, nested_diagnostics) = case node.kind(value) {
    node.Sequence(entries) -> {
      let #(entries, diagnostics) = resolve_sequence_tags(entries, handles)
      #(node.Sequence(entries), diagnostics)
    }

    node.Mapping(entries) -> {
      let #(entries, diagnostics) = resolve_mapping_tags(entries, handles)
      #(node.Mapping(entries), diagnostics)
    }

    kind -> #(kind, [])
  }

  let #(tag, tag_diagnostics) =
    node.tag(value)
    |> resolve_tag(handles, node.span(value))

  let resolved =
    node.new(kind, span: node.span(value), style: node.style(value))
    |> apply_tag(tag)
    |> copy_anchor(from: value)
    |> copy_alias(from: value)

  #(resolved, list.append(tag_diagnostics, nested_diagnostics))
}

fn resolve_sequence_tags(
  entries: List(YamlNode),
  handles: Dict(String, String),
) -> #(List(YamlNode), List(Diagnostic)) {
  let #(entries, diagnostics) =
    list.fold(entries, #([], []), fn(acc, entry) {
      let #(entries, diagnostics) = acc
      let #(entry, entry_diagnostics) = resolve_node_tags(entry, handles)

      #([entry, ..entries], list.append(diagnostics, entry_diagnostics))
    })

  #(list.reverse(entries), diagnostics)
}

fn resolve_mapping_tags(
  entries: List(#(YamlNode, YamlNode)),
  handles: Dict(String, String),
) -> #(List(#(YamlNode, YamlNode)), List(Diagnostic)) {
  let #(entries, diagnostics) =
    list.fold(entries, #([], []), fn(acc, entry) {
      let #(entries, diagnostics) = acc
      let #(key, value) = entry
      let #(key, key_diagnostics) = resolve_node_tags(key, handles)
      let #(value, value_diagnostics) = resolve_node_tags(value, handles)

      #(
        [#(key, value), ..entries],
        diagnostics
          |> list.append(key_diagnostics)
          |> list.append(value_diagnostics),
      )
    })

  #(list.reverse(entries), diagnostics)
}

fn resolve_tag(
  tag: Option(String),
  handles: Dict(String, String),
  span: node.Span,
) -> #(Option(String), List(Diagnostic)) {
  case tag {
    None -> #(None, [])
    Some(tag) ->
      case expand_tag(tag, handles, span) {
        Ok(tag) -> #(Some(tag), [])
        Error(diagnostic) -> #(Some(tag), [diagnostic])
      }
  }
}

fn expand_tag(
  tag: String,
  handles: Dict(String, String),
  span: node.Span,
) -> Result(String, Diagnostic) {
  case tag {
    "<" <> verbatim ->
      case string.ends_with(verbatim, ">") {
        True -> Ok(string.drop_end(verbatim, 1))
        False -> Ok(tag)
      }

    "!" <> suffix -> expand_tag_handle("!!", suffix, handles, span)

    _ ->
      case string.split(tag, "!") {
        [] -> expand_tag_handle("!", tag, handles, span)
        [suffix] -> expand_tag_handle("!", suffix, handles, span)
        [handle, ..suffix] ->
          expand_tag_handle(
            "!" <> handle <> "!",
            string.join(suffix, "!"),
            handles,
            span,
          )
      }
  }
}

fn expand_tag_handle(
  handle: String,
  suffix: String,
  handles: Dict(String, String),
  span: node.Span,
) -> Result(String, Diagnostic) {
  case dict.get(handles, handle) {
    Ok(prefix) -> Ok(prefix <> suffix)
    Error(_) -> Error(diagnostic.UnknownTagHandle(handle:, span:))
  }
}

fn apply_tag(value: YamlNode, tag: Option(String)) -> YamlNode {
  case tag {
    Some(tag) -> node.with_tag(value, tag)
    None -> value
  }
}

fn copy_anchor(value: YamlNode, from source: YamlNode) -> YamlNode {
  case node.anchor(source) {
    Some(anchor) -> node.with_anchor(value, anchor)
    None -> value
  }
}

fn copy_alias(value: YamlNode, from source: YamlNode) -> YamlNode {
  case node.alias(source) {
    Some(alias) -> node.with_alias(value, alias)
    None -> value
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
