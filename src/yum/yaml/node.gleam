//// Span-aware YAML node model.
////
//// This module exposes a small accessor-driven API for tooling use. The node
//// internals are opaque so future parser work can add comments, anchors, tags,
//// and richer trivia without forcing callers to change their code.

import gleam/list
import gleam/option.{type Option, None, Some}

pub opaque type Node {
  Node(
    kind: Kind,
    span: Span,
    style: Style,
    tag: Option(String),
    anchor: Option(String),
    alias: Option(String),
  )
}

/// The semantic kind of a YAML node.
///
/// This describes the value after scalar parsing, not necessarily the exact
/// source spelling. Use [`style`](#style) when source presentation matters.
pub type Kind {
  /// A YAML null value.
  ///
  /// Example YAML: `null`
  Null

  /// A boolean scalar.
  ///
  /// Example YAML: `true`
  Bool(Bool)

  /// An integer scalar.
  ///
  /// Example YAML: `42`
  Int(Int)

  /// A finite floating-point scalar.
  ///
  /// Example YAML: `3.14`
  Float(Float)

  /// Positive infinity.
  ///
  /// Example YAML: `.inf`
  PosInf

  /// Negative infinity.
  ///
  /// Example YAML: `-.inf`
  NegInf

  /// Not-a-number.
  ///
  /// Example YAML: `.nan`
  Nan

  /// A string scalar.
  ///
  /// Example YAML: `hello`
  String(String)

  /// A YAML sequence.
  ///
  /// Example YAML: `- one`
  Sequence(List(Node))

  /// A YAML mapping.
  ///
  /// Example YAML: `name: yum`
  Mapping(List(#(Node, Node)))
}

/// A lightweight name for a YAML node kind.
///
/// This is useful in diagnostics and access errors where carrying the full node
/// value would be noisy.
pub type KindName {
  /// The lightweight name for [`Null`](#Kind).
  NullKind

  /// The lightweight name for [`Bool`](#Kind).
  BoolKind

  /// The lightweight name for [`Int`](#Kind).
  IntKind

  /// The lightweight name for [`Float`](#Kind).
  FloatKind

  /// The lightweight name for [`PosInf`](#Kind).
  PosInfKind

  /// The lightweight name for [`NegInf`](#Kind).
  NegInfKind

  /// The lightweight name for [`Nan`](#Kind).
  NanKind

  /// The lightweight name for [`String`](#Kind).
  StringKind

  /// The lightweight name for [`Sequence`](#Kind).
  SequenceKind

  /// The lightweight name for [`Mapping`](#Kind).
  MappingKind
}

/// An error returned by strict node accessors.
///
pub type AccessError {
  /// The node had a different kind than the accessor required.
  ExpectedKind(expected: KindName, found: KindName, span: Span)
}

/// The source style used to write a YAML node.
///
/// Style records presentation details that are useful for tooling and
/// diagnostics. It does not change the semantic [`Kind`](#Kind).
pub type Style {
  /// A plain scalar with no quotes or block marker.
  ///
  /// Example YAML:
  /// ```yaml
  /// hello
  /// ```
  PlainScalar

  /// A single-quoted scalar.
  ///
  /// Example YAML:
  /// ```yaml
  /// 'hello'
  /// ```
  SingleQuotedScalar

  /// A double-quoted scalar.
  ///
  /// Example YAML:
  /// ```yaml
  /// "hello"
  /// ```
  DoubleQuotedScalar

  /// A literal block scalar introduced with the vertical bar marker.
  ///
  /// Example YAML:
  /// ```yaml
  /// script: |
  ///   hello
  /// ```
  LiteralBlockScalar

  /// A folded block scalar introduced with the greater-than marker.
  ///
  /// Example YAML:
  /// ```yaml
  /// description: >
  ///   hello
  /// ```
  FoldedBlockScalar

  /// A block-style sequence.
  ///
  /// Example YAML:
  /// ```yaml
  /// - one
  /// ```
  BlockSequence

  /// A flow-style sequence.
  ///
  /// Example YAML:
  /// ```yaml
  /// [one, two]
  /// ```
  FlowSequence

  /// A block-style mapping.
  ///
  /// Example YAML:
  /// ```yaml
  /// name: yum
  /// ```
  BlockMapping

  /// A flow-style mapping.
  ///
  /// Example YAML:
  /// ```yaml
  /// {name: yum}
  /// ```
  FlowMapping

  /// A generated node with no original source spelling.
  ///
  /// Builder-created nodes use this style.
  Synthetic
}

/// A half-open source span for a parsed YAML node.
///
/// Parsed spans use 1-based row and column positions. Builder-created nodes use
/// [`synthetic_span`](#synthetic_span).
pub type Span {
  Span(start: Position, end: Position)
}

/// A 1-based source position.
///
pub type Position {
  Position(row: Int, column: Int)
}

pub type PathSegment {
  /// Selects a value from a mapping by string key.
  ///
  /// Example path segment for YAML name: yum is Key("name").
  Key(String)

  /// Selects a value from a sequence by zero-based index.
  ///
  /// Example path segment for the first item is Index(0).
  Index(Int)
}

/// Creates a YAML node with explicit metadata.
///
/// Most callers should prefer [`yum/yaml.parse`](../yaml.html#parse) plus
/// [`yum/yaml.root`](../yaml.html#root) for parsed input or
/// [`yum/yaml/builder`](./builder.html) for generated YAML. This constructor is
/// public for tools that need to synthesize nodes while preserving their own
/// source metadata.
pub fn new(kind: Kind, span span: Span, style style: Style) -> Node {
  Node(kind:, span:, style:, tag: None, anchor: None, alias: None)
}

pub fn synthetic(kind: Kind) -> Node {
  new(kind, span: synthetic_span(), style: Synthetic)
}

/// Returns the placeholder span used for generated nodes with no source.
///
pub fn synthetic_span() -> Span {
  Span(start: Position(0, 0), end: Position(0, 0))
}

pub fn kind(node: Node) -> Kind {
  node.kind
}

/// Returns the node kind without its associated value.
///
pub fn kind_name(node: Node) -> KindName {
  node.kind
  |> kind_name_of
}

pub fn span(node: Node) -> Span {
  node.span
}

pub fn style(node: Node) -> Style {
  node.style
}

pub fn tag(node: Node) -> Option(String) {
  node.tag
}

pub fn anchor(node: Node) -> Option(String) {
  node.anchor
}

pub fn alias(node: Node) -> Option(String) {
  node.alias
}

/// Returns a copy of the node with tag metadata.
///
pub fn with_tag(node: Node, tag: String) -> Node {
  Node(..node, tag: Some(tag))
}

/// Returns a copy of the node with anchor metadata.
///
pub fn with_anchor(node: Node, anchor: String) -> Node {
  Node(..node, anchor: Some(anchor))
}

/// Returns a copy of the node with alias metadata.
///
pub fn with_alias(node: Node, alias: String) -> Node {
  Node(..node, alias: Some(alias))
}

pub fn as_mapping(node: Node) -> Result(List(#(Node, Node)), AccessError) {
  case node.kind {
    Mapping(entries) -> Ok(entries)
    _ -> Error(expected(node, to_be: MappingKind))
  }
}

pub fn as_sequence(node: Node) -> Result(List(Node), AccessError) {
  case node.kind {
    Sequence(entries) -> Ok(entries)
    _ -> Error(expected(node, to_be: SequenceKind))
  }
}

pub fn as_string(node: Node) -> Result(String, AccessError) {
  case node.kind {
    String(value) -> Ok(value)
    _ -> Error(expected(node, to_be: StringKind))
  }
}

pub fn as_bool(node: Node) -> Result(Bool, AccessError) {
  case node.kind {
    Bool(value) -> Ok(value)
    _ -> Error(expected(node, to_be: BoolKind))
  }
}

pub fn as_int(node: Node) -> Result(Int, AccessError) {
  case node.kind {
    Int(value) -> Ok(value)
    _ -> Error(expected(node, to_be: IntKind))
  }
}

pub fn as_float(node: Node) -> Result(Float, AccessError) {
  case node.kind {
    Float(value) -> Ok(value)
    _ -> Error(expected(node, to_be: FloatKind))
  }
}

pub fn as_null(node: Node) -> Result(Nil, AccessError) {
  case node.kind {
    Null -> Ok(Nil)
    _ -> Error(expected(node, to_be: NullKind))
  }
}

pub fn get(node: Node, path: List(PathSegment)) -> Option(Node) {
  case path {
    [] -> Some(node)
    [Key(key), ..rest] -> {
      get_key(node, key) |> option.then(get(_, rest))
    }
    [Index(index), ..rest] -> {
      get_index(node, index) |> option.then(get(_, rest))
    }
  }
}

pub fn get_key(node: Node, key: String) -> Option(Node) {
  case as_mapping(node) {
    Ok(entries) ->
      entries
      |> list.find_map(fn(entry) {
        let #(entry_key, value) = entry
        case as_string(entry_key) {
          Ok(entry_key) if entry_key == key -> Ok(value)
          _ -> Error(Nil)
        }
      })
      |> option.from_result()
    Error(_) -> None
  }
}

pub fn get_index(node: Node, index: Int) -> Option(Node) {
  case index < 0 {
    True -> None
    False -> {
      case as_sequence(node) {
        Ok(entries) ->
          entries
          |> list.drop(index)
          |> list.first()
          |> option.from_result()
        Error(_) -> None
      }
    }
  }
}

fn expected(node: Node, to_be kind: KindName) -> AccessError {
  ExpectedKind(expected: kind, found: kind_name(node), span: node.span)
}

fn kind_name_of(kind: Kind) -> KindName {
  case kind {
    Null -> NullKind
    Bool(_) -> BoolKind
    Int(_) -> IntKind
    Float(_) -> FloatKind
    PosInf -> PosInfKind
    NegInf -> NegInfKind
    Nan -> NanKind
    String(_) -> StringKind
    Sequence(_) -> SequenceKind
    Mapping(_) -> MappingKind
  }
}
