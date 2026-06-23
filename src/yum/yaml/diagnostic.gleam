//// Diagnostics for parsed YAML nodes.

import gleam/dict
import gleam/float
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import yum/yaml/node.{type Span, type YamlNode}

pub type Severity {
  Warning
  DiagnosticError
}

pub type Related {
  /// The first occurrence of a duplicate mapping key.
  FirstMappingKey(span: Span)
}

pub type Diagnostic {
  /// A mapping contains the same scalar key more than once.
  ///
  /// `duplicate` is the repeated key's span. `original` is the first matching
  /// key's span.
  DuplicateMappingKey(key: String, duplicate: Span, original: Span)
}

type SeenKey {
  SeenKey(label: String, span: Span)
}

/// Collects non-fatal diagnostics for a parsed YAML node tree.
///
pub fn collect(value: YamlNode) -> List(Diagnostic) {
  case node.kind(value) {
    node.Mapping(entries) ->
      list.append(
        duplicate_key_diagnostics(entries),
        nested_diagnostics(entries),
      )

    node.Sequence(entries) -> list.flat_map(entries, collect)

    _ -> []
  }
}

fn nested_diagnostics(
  entries: List(#(YamlNode, YamlNode)),
) -> List(Diagnostic) {
  entries
  |> list.flat_map(fn(entry) {
    let #(key, value) = entry
    list.append(collect(key), collect(value))
  })
}

fn duplicate_key_diagnostics(
  entries: List(#(YamlNode, YamlNode)),
) -> List(Diagnostic) {
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

fn duplicate_key_diagnostic(duplicate: YamlNode, first: SeenKey) -> Diagnostic {
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
  }
}

/// Renders a human-readable diagnostic message.
///
pub fn message(diagnostic: Diagnostic) -> String {
  case diagnostic {
    DuplicateMappingKey(key:, ..) -> "Duplicate mapping key `" <> key <> "`"
  }
}

/// Returns the primary source span for a diagnostic.
///
pub fn span(diagnostic: Diagnostic) -> Span {
  case diagnostic {
    DuplicateMappingKey(duplicate:, ..) -> duplicate
  }
}

/// Returns related source locations for a diagnostic.
///
pub fn related(diagnostic: Diagnostic) -> List(Related) {
  case diagnostic {
    DuplicateMappingKey(original:, ..) -> [FirstMappingKey(span: original)]
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

fn key_identity(key: YamlNode) -> Option(String) {
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

fn key_label(key: YamlNode) -> String {
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
