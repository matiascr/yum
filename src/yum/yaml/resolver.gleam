//// YAML resolver implementation.
////
//// This module contains the semantic YAML phase used by
//// [`yum/yaml.resolve`](../yaml.html#resolve): directive validation, tag handle
//// expansion, and document-wide diagnostics.

import gleam/dict.{type Dict}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import yum/yaml/diagnostic.{type Diagnostic}
import yum/yaml/document
import yum/yaml/node.{type Node}

/// Resolves a parsed document root and directives.
///
/// Returns the resolved root and non-fatal diagnostics when resolution
/// succeeds. Returns all diagnostics when a fatal diagnostic is found.
pub fn resolve(
  root: Node,
  directives: List(document.Directive),
) -> Result(#(Node, List(Diagnostic)), List(Diagnostic)) {
  let #(tag_handles, directive_diagnostics) =
    directives
    |> tag_handles()

  let #(root, tag_diagnostics) =
    root
    |> resolve_node_tags(tag_handles)

  let diagnostics =
    []
    |> list.append(directive_diagnostics)
    |> list.append(tag_diagnostics)
    |> list.append(diagnostic.collect(root))

  case diagnostic.has_errors(diagnostics) {
    True -> Error(diagnostics)
    False -> Ok(#(root, diagnostics))
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
