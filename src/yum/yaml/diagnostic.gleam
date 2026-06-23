//// Diagnostics for parsed YAML nodes.

import gleam/dict.{type Dict}
import gleam/float
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import yum/yaml/node.{type Node, type Span}

pub type Severity {
  /// A non-fatal diagnostic.
  ///
  /// Resolution can still succeed when a diagnostic has this severity.
  Warning

  /// A fatal diagnostic.
  ///
  /// Resolution returns an error when any diagnostic has this severity.
  DiagnosticError
}

pub type Related {
  /// The first occurrence of a duplicate mapping key.
  FirstMappingKey(span: Span)
}

pub type Diagnostic {
  /// A mapping contains the same scalar key more than once.
  ///
  /// The duplicate span points at the repeated key. The original span points
  /// at the first matching key.
  DuplicateMappingKey(key: String, duplicate: Span, original: Span)

  /// An alias references an anchor that has not been seen earlier in the
  /// document.
  UnknownAlias(alias: String, span: Span)

  /// A TAG directive is malformed.
  InvalidTagDirective(span: Span)

  /// A node tag uses a handle that has not been declared for the document.
  UnknownTagHandle(handle: String, span: Span)

  /// A merge key points at a value that is not a mapping.
  InvalidMergeTarget(found: node.KindName, span: Span)
}

type SeenKey {
  SeenKey(label: String, span: Span)
}

/// Collects non-fatal diagnostics for a parsed YAML node tree.
///
pub fn collect(value: Node) -> List(Diagnostic) {
  let #(_, diagnostics) = collect_with_anchors(value, dict.new())
  diagnostics
}

fn collect_with_anchors(
  value: Node,
  anchors: Dict(String, Node),
) -> #(Dict(String, Node), List(Diagnostic)) {
  let #(anchors, property_diagnostics) = collect_node_properties(value, anchors)

  let #(anchors, nested_diagnostics) = case node.kind(value) {
    node.Mapping(entries) -> collect_mapping_entries(entries, anchors)

    node.Sequence(entries) -> collect_sequence_entries(entries, anchors)

    _ -> #(anchors, [])
  }

  #(anchors, list.append(property_diagnostics, nested_diagnostics))
}

fn collect_node_properties(
  value: Node,
  anchors: Dict(String, Node),
) -> #(Dict(String, Node), List(Diagnostic)) {
  let diagnostics = case node.alias(value) {
    Some(alias) ->
      case dict.has_key(anchors, alias) {
        True -> []
        False -> [UnknownAlias(alias:, span: node.span(value))]
      }
    None -> []
  }

  let anchors = case node.anchor(value) {
    Some(anchor) -> dict.insert(anchors, anchor, value)
    None -> anchors
  }

  #(anchors, diagnostics)
}

fn collect_mapping_entries(
  entries: List(#(Node, Node)),
  anchors: Dict(String, Node),
) -> #(Dict(String, Node), List(Diagnostic)) {
  let #(anchors, nested_diagnostics) =
    list.fold(entries, #(anchors, []), fn(acc, entry) {
      let #(anchors, diagnostics) = acc
      let #(key, value) = entry
      let #(anchors, key_diagnostics) = collect_with_anchors(key, anchors)
      let #(anchors, value_diagnostics) = collect_with_anchors(value, anchors)

      #(
        anchors,
        list.append(
          diagnostics,
          list.append(key_diagnostics, value_diagnostics),
        ),
      )
    })

  #(
    anchors,
    list.append(duplicate_key_diagnostics(entries), nested_diagnostics),
  )
}

fn collect_sequence_entries(
  entries: List(Node),
  anchors: Dict(String, Node),
) -> #(Dict(String, Node), List(Diagnostic)) {
  list.fold(entries, #(anchors, []), fn(acc, entry) {
    let #(anchors, diagnostics) = acc
    let #(anchors, entry_diagnostics) = collect_with_anchors(entry, anchors)

    #(anchors, list.append(diagnostics, entry_diagnostics))
  })
}

fn duplicate_key_diagnostics(entries: List(#(Node, Node))) -> List(Diagnostic) {
  let #(_, diagnostics) =
    list.fold(entries, #(dict.new(), []), fn(acc, entry) {
      let #(seen, diagnostics) = acc
      let #(key, _) = entry

      case key_identity(key) {
        None -> acc
        Some(identity) ->
          case dict.get(seen, identity) {
            Ok(first) -> #(seen, [
              duplicate_key_diagnostic(key, first),
              ..diagnostics
            ])
            Error(_) -> #(
              dict.insert(
                seen,
                identity,
                SeenKey(label: key_label(key), span: node.span(key)),
              ),
              diagnostics,
            )
          }
      }
    })

  list.reverse(diagnostics)
}

fn duplicate_key_diagnostic(duplicate: Node, first: SeenKey) -> Diagnostic {
  DuplicateMappingKey(
    key: first.label,
    duplicate: node.span(duplicate),
    original: first.span,
  )
}

/// Returns the severity for a diagnostic variant.
///
pub fn severity(diagnostic: Diagnostic) -> Severity {
  case diagnostic {
    DuplicateMappingKey(..) -> Warning
    UnknownAlias(..) -> DiagnosticError
    InvalidTagDirective(..) -> DiagnosticError
    UnknownTagHandle(..) -> DiagnosticError
    InvalidMergeTarget(..) -> DiagnosticError
  }
}

/// Returns True when a diagnostic is fatal.
///
pub fn is_error(diagnostic: Diagnostic) -> Bool {
  severity(diagnostic) == DiagnosticError
}

/// Returns True when any diagnostic is fatal.
///
pub fn has_errors(diagnostics: List(Diagnostic)) -> Bool {
  diagnostics
  |> list.any(satisfying: is_error)
}

/// Keeps only fatal diagnostics.
///
pub fn errors(diagnostics: List(Diagnostic)) -> List(Diagnostic) {
  diagnostics
  |> list.filter(keeping: is_error)
}

/// Keeps only warning diagnostics.
///
pub fn warnings(diagnostics: List(Diagnostic)) -> List(Diagnostic) {
  diagnostics
  |> list.filter(keeping: fn(diagnostic) { !is_error(diagnostic) })
}

/// Renders a human-readable diagnostic message.
///
pub fn message(diagnostic: Diagnostic) -> String {
  case diagnostic {
    DuplicateMappingKey(key:, ..) -> "Duplicate mapping key `" <> key <> "`"
    UnknownAlias(alias:, ..) -> "Unknown alias `" <> alias <> "`"
    InvalidTagDirective(..) -> "Invalid %TAG directive"
    UnknownTagHandle(handle:, ..) -> "Unknown tag handle `" <> handle <> "`"
    InvalidMergeTarget(..) -> "Merge key must reference a mapping"
  }
}

/// Returns the primary source span for a diagnostic.
///
pub fn span(diagnostic: Diagnostic) -> Span {
  case diagnostic {
    DuplicateMappingKey(duplicate:, ..) -> duplicate
    UnknownAlias(span:, ..) -> span
    InvalidTagDirective(span:) -> span
    UnknownTagHandle(span:, ..) -> span
    InvalidMergeTarget(span:, ..) -> span
  }
}

/// Returns related source locations for a diagnostic.
///
pub fn related(diagnostic: Diagnostic) -> List(Related) {
  case diagnostic {
    DuplicateMappingKey(original:, ..) -> [FirstMappingKey(span: original)]
    UnknownAlias(..) -> []
    InvalidTagDirective(..) -> []
    UnknownTagHandle(..) -> []
    InvalidMergeTarget(..) -> []
  }
}

/// Renders a human-readable related-location message.
///
pub fn related_message(related: Related) -> String {
  case related {
    FirstMappingKey(..) -> "First key appears here"
  }
}

/// Returns the source span for a related location.
///
pub fn related_span(related: Related) -> Span {
  case related {
    FirstMappingKey(span:) -> span
  }
}

fn key_identity(key: Node) -> Option(String) {
  case node.kind(key) {
    node.Null -> Some("null:")
    node.Bool(value) -> Some("bool:" <> bool_identity(value))
    node.Int(value) -> Some("int:" <> int.to_string(value))
    node.Float(value) -> Some("float:" <> float.to_string(value))
    node.PosInf -> Some("float:.inf")
    node.NegInf -> Some("float:-.inf")
    node.Nan -> Some("float:.nan")
    node.String(value) -> Some("string:" <> value)
    node.Sequence(_) | node.Mapping(_) -> None
  }
}

fn key_label(key: Node) -> String {
  case node.kind(key) {
    node.Null -> "null"
    node.Bool(value) -> bool_identity(value)
    node.Int(value) -> int.to_string(value)
    node.Float(value) -> float.to_string(value)
    node.PosInf -> ".inf"
    node.NegInf -> "-.inf"
    node.Nan -> ".nan"
    node.String(value) -> value
    node.Sequence(_) | node.Mapping(_) -> "<complex key>"
  }
}

fn bool_identity(value: Bool) -> String {
  case value {
    True -> "true"
    False -> "false"
  }
}
