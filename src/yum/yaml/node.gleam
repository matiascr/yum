//// Span-aware YAML node model.
////
//// This module exposes a small accessor-driven API for tooling use. The node
//// internals are opaque so future parser work can add comments, anchors, tags,
//// and richer trivia without forcing callers to change their code.

import gleam/list
import gleam/option.{type Option, None, Some}
import yum/yaml/ast.{type YamlAST}

pub opaque type YamlNode {
  YamlNode(
    kind: YamlKind,
    span: Span,
    style: YamlStyle,
    tag: Option(String),
    anchor: Option(String),
    alias: Option(String),
  )
}

pub type YamlKind {
  Null
  Bool(Bool)
  Int(Int)
  Float(Float)
  PosInf
  NegInf
  Nan
  String(String)
  Sequence(List(YamlNode))
  Mapping(List(#(YamlNode, YamlNode)))
}

pub type YamlStyle {
  PlainScalar
  SingleQuotedScalar
  DoubleQuotedScalar
  LiteralBlockScalar
  FoldedBlockScalar
  BlockSequence
  FlowSequence
  BlockMapping
  FlowMapping
  Synthetic
}

/// A half-open source span for a parsed YAML node.
///
/// Parsed spans use 1-based row and column positions. Builder-created nodes use
/// `synthetic_span`.
pub type Span {
  Span(start: Position, end: Position)
}

/// A 1-based source position.
///
pub type Position {
  Position(row: Int, column: Int)
}

pub type PathSegment {
  Key(String)
  Index(Int)
}

/// Creates a YAML node with explicit metadata.
///
/// Most callers should prefer `yum/yaml.parse_node` for parsed input or
/// `yum/yaml/builder` for generated YAML. This constructor is public for tools
/// that need to synthesize nodes while preserving their own source metadata.
pub fn new(
  kind: YamlKind,
  span span: Span,
  style style: YamlStyle,
) -> YamlNode {
  YamlNode(kind:, span:, style:, tag: None, anchor: None, alias: None)
}

pub fn synthetic(kind: YamlKind) -> YamlNode {
  new(kind, span: synthetic_span(), style: Synthetic)
}

/// Returns the placeholder span used for generated nodes with no source.
///
pub fn synthetic_span() -> Span {
  Span(start: Position(0, 0), end: Position(0, 0))
}

pub fn kind(node: YamlNode) -> YamlKind {
  node.kind
}

pub fn span(node: YamlNode) -> Span {
  node.span
}

pub fn style(node: YamlNode) -> YamlStyle {
  node.style
}

pub fn tag(node: YamlNode) -> Option(String) {
  node.tag
}

pub fn anchor(node: YamlNode) -> Option(String) {
  node.anchor
}

pub fn alias(node: YamlNode) -> Option(String) {
  node.alias
}

pub fn as_mapping(node: YamlNode) -> Option(List(#(YamlNode, YamlNode))) {
  case node.kind {
    Mapping(entries) -> Some(entries)
    _ -> None
  }
}

pub fn as_sequence(node: YamlNode) -> Option(List(YamlNode)) {
  case node.kind {
    Sequence(entries) -> Some(entries)
    _ -> None
  }
}

pub fn as_string(node: YamlNode) -> Option(String) {
  case node.kind {
    String(value) -> Some(value)
    _ -> None
  }
}

pub fn as_bool(node: YamlNode) -> Option(Bool) {
  case node.kind {
    Bool(value) -> Some(value)
    _ -> None
  }
}

pub fn as_int(node: YamlNode) -> Option(Int) {
  case node.kind {
    Int(value) -> Some(value)
    _ -> None
  }
}

pub fn as_float(node: YamlNode) -> Option(Float) {
  case node.kind {
    Float(value) -> Some(value)
    _ -> None
  }
}

pub fn get(node: YamlNode, path: List(PathSegment)) -> Option(YamlNode) {
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

pub fn get_key(node: YamlNode, key: String) -> Option(YamlNode) {
  use entries <- option.then(as_mapping(node))

  entries
  |> list.find_map(fn(entry) {
    let #(entry_key, value) = entry
    case as_string(entry_key) {
      Some(entry_key) if entry_key == key -> Ok(value)
      _ -> Error(Nil)
    }
  })
  |> option.from_result()
}

pub fn get_index(node: YamlNode, index: Int) -> Option(YamlNode) {
  case index < 0 {
    True -> None
    False -> {
      use entries <- option.then(as_sequence(node))
      entries
      |> list.drop(index)
      |> list.first()
      |> option.from_result()
    }
  }
}

pub fn to_ast(node: YamlNode) -> YamlAST {
  case node.kind {
    Null -> ast.Null
    Bool(value) -> ast.Bool(value)
    Int(value) -> ast.Int(value)
    Float(value) -> ast.Float(value)
    PosInf -> ast.PosInf
    NegInf -> ast.NegInf
    Nan -> ast.Nan
    String(value) -> ast.String(value)
    Sequence(entries) -> ast.Sequence(list.map(entries, to_ast))
    Mapping(entries) ->
      entries
      |> list.map(fn(entry) {
        let #(key, value) = entry
        #(to_ast(key), to_ast(value))
      })
      |> ast.Mapping
  }
}

pub fn from_ast(value: YamlAST) -> YamlNode {
  case value {
    ast.Null -> synthetic(Null)
    ast.Bool(value) -> synthetic(Bool(value))
    ast.Int(value) -> synthetic(Int(value))
    ast.Float(value) -> synthetic(Float(value))
    ast.PosInf -> synthetic(PosInf)
    ast.NegInf -> synthetic(NegInf)
    ast.Nan -> synthetic(Nan)
    ast.String(value) -> synthetic(String(value))
    ast.Sequence(entries) -> synthetic(Sequence(list.map(entries, from_ast)))
    ast.Mapping(entries) ->
      entries
      |> list.map(fn(entry) {
        let #(key, value) = entry
        #(from_ast(key), from_ast(value))
      })
      |> Mapping
      |> synthetic
  }
}
