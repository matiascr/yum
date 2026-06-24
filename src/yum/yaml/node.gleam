//// Inspect and query YAML nodes.
////
//// A [`Node`](#Node) is one value inside a YAML document: a scalar, sequence,
//// or mapping. This module provides accessors for the node kind, source span,
//// source style, tags, anchors, aliases, typed scalar values, and nested path
//// lookup.
////
//// Nodes are used by both raw and resolved YAML documents. Parsing creates
//// nodes with the structure and metadata found in the source. Resolving
//// validates YAML-level metadata such as aliases and tags, and may expand or
//// compose parts of the tree, but a resolved document still contains nodes.
////
//// For example, [`tag`](#tag), [`anchor`](#anchor), and [`alias`](#alias)
//// expose YAML metadata attached to a node. That metadata is not the same as
//// the node's semantic [`Kind`](#Kind). Nodes created with
//// [`yum/yaml/builder`](./builder.html) are synthetic and use
//// [`synthetic_span`](#synthetic_span).

import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result

/// A YAML value with source metadata.
///
/// Nodes can represent scalars, sequences, and mappings. Parsed nodes carry
/// their source span and presentation style. Builder-created nodes are
/// synthetic and use [`Synthetic`](#Style) style plus [`synthetic_span`](#synthetic_span).
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

/// One step in a nested YAML lookup path.
///
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

/// Creates a generated node with no original source location.
///
/// This is the lower-level constructor used by [`yum/yaml/builder`](./builder.html).
pub fn synthetic(kind: Kind) -> Node {
  new(kind, span: synthetic_span(), style: Synthetic)
}

/// Returns the placeholder span used for generated nodes with no source.
///
pub fn synthetic_span() -> Span {
  Span(start: Position(0, 0), end: Position(0, 0))
}

/// Returns the semantic kind and value of a node.
///
/// This is the broadest accessor. Prefer the stricter `as_*` functions when a
/// caller expects one specific YAML kind and wants a typed error for mismatches.
pub fn kind(node: Node) -> Kind {
  node.kind
}

/// Returns the node kind without its associated value.
///
pub fn kind_name(node: Node) -> KindName {
  node.kind
  |> kind_name_of
}

/// Returns the source span for a node.
///
/// Parsed nodes use 1-based row and column positions. Synthetic nodes created
/// with [`yum/yaml/builder`](./builder.html) use [`synthetic_span`](#synthetic_span).
pub fn span(node: Node) -> Span {
  node.span
}

/// Returns the source style used to write a node.
///
/// Style describes presentation, such as plain versus quoted scalars or block
/// versus flow collections. It does not change the node's semantic kind.
pub fn style(node: Node) -> Style {
  node.style
}

/// Returns the YAML tag attached to a node, if one was written or added.
///
/// Tags are metadata, not value casts. A tagged scalar keeps its parsed
/// [`Kind`](#Kind); for example `!!str 123` is still parsed as an integer today,
/// while the tag is available through this function.
///
/// On raw YAML, this returns the tag form captured by the parser. On resolved
/// YAML, tag handles are expanded where possible. For example:
///
/// ```gleam
/// import gleam/option
/// import yum/yaml
/// import yum/yaml/node
///
/// pub fn example() {
///   let assert Ok(document) = yaml.parse("value: !!str 123")
///   let assert option.Some(value) = document |> yaml.get([node.Key("value")])
///
///   assert node.tag(value) == option.Some("!str")
///
///   let assert Ok(document) = yaml.resolve(document)
///   let assert option.Some(value) = document |> yaml.get([node.Key("value")])
///
///   assert node.tag(value) == option.Some("tag:yaml.org,2002:str")
/// }
/// ```
pub fn tag(node: Node) -> Option(String) {
  node.tag
}

/// Returns the YAML anchor name attached to a node, if one was written or added.
///
/// For source YAML like `defaults: &base { retries: 1 }`, the value node under
/// `defaults` has anchor `base`. Resolving validates duplicate anchors but does
/// not remove anchor metadata from nodes.
pub fn anchor(node: Node) -> Option(String) {
  node.anchor
}

/// Returns the YAML alias name attached to a node, if one was written or added.
///
/// For source YAML like `copy: *base`, the value node under `copy` has alias
/// `base`. Resolving checks that aliases refer to anchors seen earlier in the
/// document, but alias metadata can still be inspected on the node.
pub fn alias(node: Node) -> Option(String) {
  node.alias
}

/// Returns a copy of the node with tag metadata.
///
/// This function only sets metadata. It does not validate tag syntax or change
/// the node's [`Kind`](#Kind).
///
pub fn with_tag(node: Node, tag: String) -> Node {
  Node(..node, tag: Some(tag))
}

/// Returns a copy of the node with anchor metadata.
///
/// This function only sets metadata. Use [`yum/yaml.resolve`](../yaml.html#resolve)
/// to validate anchor and alias relationships.
///
pub fn with_anchor(node: Node, anchor: String) -> Node {
  Node(..node, anchor: Some(anchor))
}

/// Returns a copy of the node with alias metadata.
///
/// This function only sets metadata. Use [`yum/yaml.resolve`](../yaml.html#resolve)
/// to check whether the alias refers to a known anchor.
///
pub fn with_alias(node: Node, alias: String) -> Node {
  Node(..node, alias: Some(alias))
}

/// Returns mapping entries when the node is a mapping.
///
/// Returns [`ExpectedKind`](#AccessError) when the node is not a mapping.
pub fn as_mapping(node: Node) -> Result(List(#(Node, Node)), AccessError) {
  case node.kind {
    Mapping(entries) -> Ok(entries)
    _ -> Error(expected(node, to_be: MappingKind))
  }
}

/// Returns all keys from a mapping node.
///
/// The keys are returned as nodes because YAML mappings can use scalar,
/// sequence, or mapping nodes as keys. Returns [`ExpectedKind`](#AccessError)
/// when the node is not a mapping.
pub fn get_keys(node: Node) -> Result(List(Node), AccessError) {
  node
  |> as_mapping()
  |> result.map(
    list.map(_, fn(entry) {
      let #(key, _) = entry
      key
    }),
  )
}

/// Returns all values from a mapping node.
///
/// Values are returned in source order. Returns [`ExpectedKind`](#AccessError)
/// when the node is not a mapping.
pub fn get_values(node: Node) -> Result(List(Node), AccessError) {
  node
  |> as_mapping
  |> result.map(fn(node) {
    list.map(node, fn(entry) {
      let #(_, value) = entry
      value
    })
  })
}

/// Returns sequence entries when the node is a sequence.
///
/// Returns [`ExpectedKind`](#AccessError) when the node is not a sequence.
pub fn as_sequence(node: Node) -> Result(List(Node), AccessError) {
  case node.kind {
    Sequence(entries) -> Ok(entries)
    _ -> Error(expected(node, to_be: SequenceKind))
  }
}

/// Returns the string value when the node is a string.
///
/// Returns [`ExpectedKind`](#AccessError) when the node is not a string.
pub fn as_string(node: Node) -> Result(String, AccessError) {
  case node.kind {
    String(value) -> Ok(value)
    _ -> Error(expected(node, to_be: StringKind))
  }
}

/// Returns the boolean value when the node is a boolean.
///
/// Returns [`ExpectedKind`](#AccessError) when the node is not a boolean.
pub fn as_bool(node: Node) -> Result(Bool, AccessError) {
  case node.kind {
    Bool(value) -> Ok(value)
    _ -> Error(expected(node, to_be: BoolKind))
  }
}

/// Returns the integer value when the node is an integer.
///
/// Returns [`ExpectedKind`](#AccessError) when the node is not an integer.
pub fn as_int(node: Node) -> Result(Int, AccessError) {
  case node.kind {
    Int(value) -> Ok(value)
    _ -> Error(expected(node, to_be: IntKind))
  }
}

/// Returns the finite float value when the node is a float.
///
/// Returns [`ExpectedKind`](#AccessError) when the node is not a finite float.
/// Special float values have separate kinds: [`PosInf`](#Kind),
/// [`NegInf`](#Kind), and [`Nan`](#Kind).
pub fn as_float(node: Node) -> Result(Float, AccessError) {
  case node.kind {
    Float(value) -> Ok(value)
    _ -> Error(expected(node, to_be: FloatKind))
  }
}

/// Returns `Nil` when the node is null.
///
/// Returns [`ExpectedKind`](#AccessError) when the node is not null.
pub fn as_null(node: Node) -> Result(Nil, AccessError) {
  case node.kind {
    Null -> Ok(Nil)
    _ -> Error(expected(node, to_be: NullKind))
  }
}

/// Returns a nested node by following mapping keys and sequence indexes.
///
/// This is a convenience wrapper around [`get_key`](#get_key) and
/// [`get_index`](#get_index). It returns `None` when any path segment does not
/// match the current node.
///
/// ```gleam
/// import gleam/option
/// import yum/yaml
/// import yum/yaml/node
///
/// pub fn example() {
///   let assert Ok(document) = yaml.parse("jobs:\n  test:\n    run: gleam test")
///   let root = yaml.root(document)
///
///   let run = root |> node.get([
///     node.Key("jobs"),
///     node.Key("test"),
///     node.Key("run"),
///   ])
///
///   let value = run |> option.map(node.as_string)
///
///   assert value == option.Some(Ok("gleam test"))
/// }
/// ```
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

/// Returns a mapping value by string key.
///
/// Only string keys are matched. Returns `None` when the node is not a mapping,
/// when the key is not present, or when a mapping entry uses a non-string key.
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

/// Returns a sequence item by zero-based index.
///
/// Returns `None` when the node is not a sequence or when the index is out of
/// bounds. Negative indexes always return `None`.
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
