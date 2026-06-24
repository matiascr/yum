//// Parse, resolve, query, decode, and emit YAML documents.
////
//// This is the main public module. It parses strings into opaque YAML
//// documents, resolves YAML-level metadata such as aliases and tags, retrieves
//// nested nodes by path, decodes documents with `gleam/dynamic/decode`, and
//// emits YAML strings from parsed or built documents.
////
//// ```gleam
//// import gleam/option
//// import yum/yaml
//// import yum/yaml/node
////
//// pub fn example() {
////   let assert Ok(document) = yaml.parse("name: yum")
////
////   let name =
////     document
////     |> yaml.get([node.Key("name")])
////     |> option.map(node.as_string)
////
////   assert name == option.Some(Ok("yum"))
//// }
//// ```
////
//// Use [`parse`](#parse) when you want a single YAML document value. Use
//// [`parse_stream`](#parse_stream) for YAML streams containing zero or more
//// explicit documents.
////
//// Parsed YAML is raw syntax. Pipe it into [`resolve`](#resolve) to run the
//// semantic YAML phase that validates anchors, aliases, directives, and tags.
////

import gleam/bool
import gleam/dynamic/decode as dynamic_decode
import gleam/int
import gleam/list
import gleam/option.{type Option}
import gleam/result
import gleam/string
import yum/yaml/diagnostic.{type Diagnostic}
import yum/yaml/document.{type Document}
import yum/yaml/dynamic as yaml_dynamic
import yum/yaml/emitter
import yum/yaml/error.{type YamlError}
import yum/yaml/lexer
import yum/yaml/node.{type AccessError, type Node, type PathSegment}
import yum/yaml/parser
import yum/yaml/resolver

pub type DecodeError {
  /// The input could not be parsed as YAML.
  ParseError(YamlError)

  /// The input parsed, but YAML resolution found fatal diagnostics.
  ResolveError(List(Diagnostic))

  /// YAML resolution succeeded, but the dynamic decoder rejected the value.
  UnableToDecode(List(dynamic_decode.DecodeError))
}

/// A YAML directive from the beginning of a document.
///
/// Directives are preserved for tooling and semantic resolution. For example,
/// a TAG directive contributes a tag handle that resolution can use.
pub type Directive {
  /// The directive name, its whitespace-separated parameters, and source span.
  Directive(name: String, parameters: List(String), span: node.Span)
}

/// A YAML document.
///
/// Raw YAML has passed syntax parsing. Resolved YAML has also passed the
/// semantic YAML phase, which validates anchors, aliases, directives, and tags.
/// The type is opaque so callers use accessors rather than depending on the
/// internal document representation.
pub opaque type Yaml {
  Raw(YamlInternal)
  Resolved(YamlInternal, diagnostics: List(Diagnostic))
}

type YamlInternal {
  YamlInternal(root: Node, directives: List(document.Directive))
}

/// Parses a YAML file into a YAML document.
///
/// Follows the [YAML 1.2 specification](https://yaml.org/spec/1.2.2/)
///
pub fn parse(input: String) -> Result(Yaml, YamlError) {
  use documents <- result.try(parse_stream(input))

  case documents {
    [document] -> Ok(document)
    [_, _, ..] -> Error(error.multiple_documents())
    [] -> Error(error.unexpected_end_of_input())
  }
}

/// Parses a YAML stream into a list of YAML documents.
///
pub fn parse_stream(input: String) -> Result(List(Yaml), YamlError) {
  input
  |> parse_document_stream()
  |> result.map(list.map(_, raw_from_document))
}

fn parse_document_stream(input: String) -> Result(List(Document), YamlError) {
  use input <- result.try(normalize_whitespace(input, 0))
  use input <- result.try(normalize_indents(input))

  use tokens <- result.try(lexer.lex(input))
  use parsed <- result.try(parser.parse_document_stream(tokens))
  Ok(parsed)
}

/// Creates a raw YAML document from a node.
///
/// This is useful with [`yum/yaml/builder`](./yaml/builder.html), which builds
/// node trees.
///
pub fn from_node(node: Node) -> Yaml {
  Raw(YamlInternal(root: node, directives: []))
}

/// Resolves raw YAML into composed YAML.
///
/// Calling this on already-resolved YAML is a no-op.
///
pub fn resolve(yaml: Yaml) -> Result(Yaml, List(Diagnostic)) {
  case yaml {
    Resolved(..) -> Ok(yaml)
    Raw(internal) -> resolve_internal(internal)
  }
}

/// Returns the document root node.
///
pub fn root(yaml: Yaml) -> Node {
  let YamlInternal(root:, ..) = internal(yaml)
  root
}

/// Returns the document directives.
///
pub fn directives(from yaml: Yaml) -> List(Directive) {
  let YamlInternal(directives:, ..) = internal(yaml)
  list.map(directives, public_directive)
}

/// Returns non-fatal diagnostics collected while resolving the document.
///
pub fn diagnostics(from yaml: Yaml) -> List(Diagnostic) {
  case yaml {
    Raw(_) -> []
    Resolved(_, diagnostics:) -> diagnostics
  }
}

/// Returns a nested node by mapping key or sequence index.
///
pub fn get(from yaml: Yaml, at path: List(PathSegment)) -> Option(Node) {
  yaml
  |> root()
  |> node.get(path)
}

/// Returns all keys from the root mapping.
///
/// The keys are returned as nodes because YAML mappings can use scalar,
/// sequence, or mapping nodes as keys. Returns [`ExpectedKind`](./yaml/node.html#AccessError)
/// when the document root is not a mapping.
pub fn get_keys(from yaml: Yaml) -> Result(List(Node), AccessError) {
  yaml
  |> root()
  |> node.get_keys()
}

/// Returns all values from the root mapping.
///
/// Values are returned in source order. Returns [`ExpectedKind`](./yaml/node.html#AccessError)
/// when the document root is not a mapping.
pub fn get_values(from yaml: Yaml) -> Result(List(Node), AccessError) {
  yaml
  |> root()
  |> node.get_values()
}

fn resolve_internal(internal: YamlInternal) -> Result(Yaml, List(Diagnostic)) {
  let YamlInternal(root:, directives:) = internal

  case resolver.resolve(root, directives) {
    Ok(#(root, diagnostics)) ->
      Ok(Resolved(YamlInternal(root:, directives:), diagnostics:))

    Error(diagnostics) -> Error(diagnostics)
  }
}

/// Parses YAML and decodes it using a
/// [`gleam/dynamic/decode`](https://hexdocs.pm/gleam_stdlib/gleam/dynamic/decode.html)
/// decoder.
///
pub fn decode(
  from input: String,
  using decoder: dynamic_decode.Decoder(t),
) -> Result(t, DecodeError) {
  use document <- result.try(
    parse(input)
    |> result.map_error(ParseError),
  )
  use document <- result.try(
    document
    |> resolve()
    |> result.map_error(ResolveError),
  )

  document
  |> root()
  |> yaml_dynamic.from_node()
  |> dynamic_decode.run(decoder)
  |> result.map_error(UnableToDecode)
}

/// Emits a deterministic YAML string from a YAML document.
///
pub fn to_string(yaml: Yaml) -> String {
  yaml
  |> root()
  |> emitter.to_string()
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
  |> result.replace_error(error.indent_normalization_error())
}

fn count_indents(input: String) -> Int {
  case input {
    " " <> rest -> 1 + count_indents(rest)
    _ -> 0
  }
}

fn raw_from_document(document: Document) -> Yaml {
  Raw(YamlInternal(
    root: document.root(document),
    directives: document.directives(document),
  ))
}

fn public_directive(directive: document.Directive) -> Directive {
  let document.Directive(name:, parameters:, span:) = directive
  Directive(name:, parameters:, span:)
}

fn internal(yaml: Yaml) -> YamlInternal {
  case yaml {
    Raw(internal) | Resolved(internal, diagnostics: _) -> internal
  }
}
