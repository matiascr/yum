//// YAML resolver implementation.
////
//// This module contains the semantic YAML phase used by
//// [`yum/yaml.resolve`](../yaml.html#resolve): directive validation, tag handle
//// expansion, and document-wide diagnostics.

import gleam/dict.{type Dict}
import gleam/float
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import yum/yaml/diagnostic.{type Diagnostic}
import yum/yaml/document
import yum/yaml/node.{type Node}

type ResolvedMappingEntry {
  ResolvedMappingEntry(key: Node, value: Node, anchors: Dict(String, Node))
}

/// Resolves a parsed document root and directives.
///
/// Returns the resolved root and non-fatal diagnostics when resolution
/// succeeds. Returns all diagnostics when a fatal diagnostic is found.
pub fn resolve(
  root: Node,
  directives: List(document.Directive),
) -> Result(#(Node, List(Diagnostic)), List(Diagnostic)) {
  let yaml_directive_diagnostics =
    directives
    |> validate_yaml_directives()

  let #(tag_handles, directive_diagnostics) =
    directives
    |> tag_handles()

  let #(root, tag_diagnostics) =
    root
    |> resolve_node_tags(tag_handles)

  let property_diagnostics = diagnostic.collect(root)
  let #(root, _, merge_diagnostics) = resolve_node_merges(root, dict.new())

  let diagnostics =
    []
    |> list.append(yaml_directive_diagnostics)
    |> list.append(directive_diagnostics)
    |> list.append(tag_diagnostics)
    |> list.append(property_diagnostics)
    |> list.append(merge_diagnostics)

  case diagnostic.has_errors(diagnostics) {
    True -> Error(diagnostics)
    False -> Ok(#(root, diagnostics))
  }
}

fn validate_yaml_directives(
  directives: List(document.Directive),
) -> List(Diagnostic) {
  let #(_, diagnostics) =
    list.fold(directives, #(None, []), fn(acc, directive) {
      let #(first_yaml, diagnostics) = acc

      case directive {
        document.Directive(name: "YAML", parameters: [version], span:) ->
          case first_yaml {
            Some(original) -> #(
              first_yaml,
              list.append(diagnostics, [
                diagnostic.DuplicateYamlDirective(
                  duplicate: span,
                  original: original,
                ),
              ]),
            )

            None ->
              case version {
                "1.2" -> #(Some(span), diagnostics)
                _ -> #(
                  Some(span),
                  list.append(diagnostics, [
                    diagnostic.UnsupportedYamlVersion(version:, span:),
                  ]),
                )
              }
          }

        document.Directive(name: "YAML", span:, ..) -> #(
          first_yaml,
          list.append(diagnostics, [diagnostic.InvalidYamlDirective(span:)]),
        )

        _ -> acc
      }
    })

  diagnostics
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
  value: Node,
  handles: Dict(String, String),
) -> #(Node, List(Diagnostic)) {
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
  entries: List(Node),
  handles: Dict(String, String),
) -> #(List(Node), List(Diagnostic)) {
  let #(entries, diagnostics) =
    list.fold(entries, #([], []), fn(acc, entry) {
      let #(entries, diagnostics) = acc
      let #(entry, entry_diagnostics) = resolve_node_tags(entry, handles)

      #([entry, ..entries], list.append(diagnostics, entry_diagnostics))
    })

  #(list.reverse(entries), diagnostics)
}

fn resolve_mapping_tags(
  entries: List(#(Node, Node)),
  handles: Dict(String, String),
) -> #(List(#(Node, Node)), List(Diagnostic)) {
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

fn resolve_node_merges(
  value: Node,
  anchors: Dict(String, Node),
) -> #(Node, Dict(String, Node), List(Diagnostic)) {
  let #(kind, anchors, nested_diagnostics) = case node.kind(value) {
    node.Sequence(entries) -> {
      let #(entries, anchors, diagnostics) =
        resolve_sequence_merges(entries, anchors)
      #(node.Sequence(entries), anchors, diagnostics)
    }

    node.Mapping(entries) -> {
      let #(entries, anchors, diagnostics) =
        resolve_mapping_merges(entries, anchors)
      #(node.Mapping(entries), anchors, diagnostics)
    }

    kind -> #(kind, anchors, [])
  }

  let value = rebuild(value, kind)
  let anchors = register_anchor(anchors, value)

  #(value, anchors, nested_diagnostics)
}

fn resolve_sequence_merges(
  entries: List(Node),
  anchors: Dict(String, Node),
) -> #(List(Node), Dict(String, Node), List(Diagnostic)) {
  let #(entries, anchors, diagnostics) =
    list.fold(entries, #([], anchors, []), fn(acc, entry) {
      let #(entries, anchors, diagnostics) = acc
      let #(entry, anchors, entry_diagnostics) =
        resolve_node_merges(entry, anchors)

      #(
        [entry, ..entries],
        anchors,
        list.append(diagnostics, entry_diagnostics),
      )
    })

  #(list.reverse(entries), anchors, diagnostics)
}

fn resolve_mapping_merges(
  entries: List(#(Node, Node)),
  anchors: Dict(String, Node),
) -> #(List(#(Node, Node)), Dict(String, Node), List(Diagnostic)) {
  let #(entries, anchors, diagnostics) =
    list.fold(entries, #([], anchors, []), fn(acc, entry) {
      let #(entries, anchors, diagnostics) = acc
      let #(key, value) = entry
      let #(key, anchors, key_diagnostics) = resolve_node_merges(key, anchors)
      let #(value, anchors, value_diagnostics) =
        resolve_node_merges(value, anchors)

      #(
        [ResolvedMappingEntry(key:, value:, anchors:), ..entries],
        anchors,
        diagnostics
          |> list.append(key_diagnostics)
          |> list.append(value_diagnostics),
      )
    })

  let #(entries, merge_diagnostics) =
    entries
    |> list.reverse()
    |> expand_mapping_merges()

  #(entries, anchors, list.append(diagnostics, merge_diagnostics))
}

fn expand_mapping_merges(
  entries: List(ResolvedMappingEntry),
) -> #(List(#(Node, Node)), List(Diagnostic)) {
  let explicit_entries =
    entries
    |> list.filter_map(fn(entry) {
      case is_merge_key(entry.key) {
        True -> Error(Nil)
        False -> Ok(#(entry.key, entry.value))
      }
    })

  let #(merged_entries, diagnostics) =
    list.fold(entries, #([], []), fn(acc, entry) {
      let #(merged_entries, diagnostics) = acc

      case is_merge_key(entry.key) {
        False -> acc
        True -> {
          let #(entries, entry_diagnostics) =
            expand_merge_value(entry.value, entry.anchors)

          #(
            list.append(merged_entries, entries),
            list.append(diagnostics, entry_diagnostics),
          )
        }
      }
    })

  let merged_entries =
    merged_entries
    |> deduplicate_merged_entries(seen_key_identities(explicit_entries))

  #(list.append(explicit_entries, merged_entries), diagnostics)
}

fn expand_merge_value(
  value: Node,
  anchors: Dict(String, Node),
) -> #(List(#(Node, Node)), List(Diagnostic)) {
  case node.alias(value) {
    Some(alias) ->
      case dict.get(anchors, alias) {
        Ok(target) -> merge_target_entries(target, node.span(value))
        Error(_) -> #([], [])
      }

    None ->
      case node.kind(value) {
        node.Mapping(entries) -> #(entries, [])
        node.Sequence(entries) -> expand_merge_sequence(entries, anchors)
        _ -> #([], [
          diagnostic.InvalidMergeTarget(
            found: node.kind_name(value),
            span: node.span(value),
          ),
        ])
      }
  }
}

fn expand_merge_sequence(
  entries: List(Node),
  anchors: Dict(String, Node),
) -> #(List(#(Node, Node)), List(Diagnostic)) {
  list.fold(entries, #([], []), fn(acc, entry) {
    let #(merged_entries, diagnostics) = acc
    let #(entries, entry_diagnostics) =
      expand_merge_sequence_entry(entry, anchors)

    #(
      list.append(merged_entries, entries),
      list.append(diagnostics, entry_diagnostics),
    )
  })
}

fn expand_merge_sequence_entry(
  entry: Node,
  anchors: Dict(String, Node),
) -> #(List(#(Node, Node)), List(Diagnostic)) {
  case node.alias(entry) {
    Some(alias) ->
      case dict.get(anchors, alias) {
        Ok(target) -> merge_target_entries(target, node.span(entry))
        Error(_) -> #([], [])
      }

    None -> merge_target_entries(entry, node.span(entry))
  }
}

fn merge_target_entries(
  target: Node,
  span: node.Span,
) -> #(List(#(Node, Node)), List(Diagnostic)) {
  case node.kind(target) {
    node.Mapping(entries) -> #(entries, [])
    _ -> #([], [
      diagnostic.InvalidMergeTarget(found: node.kind_name(target), span:),
    ])
  }
}

fn deduplicate_merged_entries(
  entries: List(#(Node, Node)),
  seen: Dict(String, Nil),
) -> List(#(Node, Node)) {
  let #(entries, _) =
    list.fold(entries, #([], seen), fn(acc, entry) {
      let #(entries, seen) = acc
      let #(key, _) = entry

      case key_identity(key) {
        None -> #([entry, ..entries], seen)
        Some(identity) ->
          case dict.has_key(seen, identity) {
            True -> acc
            False -> #([entry, ..entries], dict.insert(seen, identity, Nil))
          }
      }
    })

  list.reverse(entries)
}

fn seen_key_identities(entries: List(#(Node, Node))) -> Dict(String, Nil) {
  list.fold(entries, dict.new(), fn(seen, entry) {
    let #(key, _) = entry

    case key_identity(key) {
      None -> seen
      Some(identity) -> dict.insert(seen, identity, Nil)
    }
  })
}

fn is_merge_key(key: Node) -> Bool {
  case node.tag(key) {
    Some("tag:yaml.org,2002:merge") -> True
    _ ->
      case node.kind(key) {
        node.String("<<") -> True
        _ -> False
      }
  }
}

fn register_anchor(
  anchors: Dict(String, Node),
  value: Node,
) -> Dict(String, Node) {
  case node.anchor(value) {
    Some(anchor) -> dict.insert(anchors, anchor, value)
    None -> anchors
  }
}

fn rebuild(source: Node, kind: node.Kind) -> Node {
  node.new(kind, span: node.span(source), style: node.style(source))
  |> apply_tag(node.tag(source))
  |> copy_anchor(from: source)
  |> copy_alias(from: source)
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

fn apply_tag(value: Node, tag: Option(String)) -> Node {
  case tag {
    Some(tag) -> node.with_tag(value, tag)
    None -> value
  }
}

fn copy_anchor(value: Node, from source: Node) -> Node {
  case node.anchor(source) {
    Some(anchor) -> node.with_anchor(value, anchor)
    None -> value
  }
}

fn copy_alias(value: Node, from source: Node) -> Node {
  case node.alias(source) {
    Some(alias) -> node.with_alias(value, alias)
    None -> value
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

fn bool_identity(value: Bool) -> String {
  case value {
    True -> "true"
    False -> "false"
  }
}
