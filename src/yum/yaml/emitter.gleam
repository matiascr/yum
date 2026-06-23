import gleam/float
import gleam/int
import gleam/list
import gleam/option.{Some}
import gleam/string
import yum/yaml/node.{type YamlNode}
import yum/yaml/parser/scalar

pub fn to_string(value: YamlNode) -> String {
  emit(value, 0)
}

fn emit(value: YamlNode, indent: Int) -> String {
  case node.kind(value) {
    node.Null -> "null"
    node.Bool(True) -> "true"
    node.Bool(False) -> "false"
    node.Int(value) -> int.to_string(value)
    node.Float(value) -> float.to_string(value)
    node.PosInf -> ".inf"
    node.NegInf -> "-.inf"
    node.Nan -> ".nan"
    node.String(value) -> emit_string(value)
    node.Sequence(entries) -> emit_sequence(entries, indent)
    node.Mapping(entries) -> emit_mapping(entries, indent)
  }
}

fn emit_sequence(entries: List(YamlNode), indent: Int) -> String {
  case entries {
    [] -> "[]"
    [_, ..] ->
      entries
      |> list.map(fn(entry) {
        case node.kind(entry) {
          node.Mapping([_, ..]) | node.Sequence([_, ..]) ->
            emit_nested_sequence_entry(entry, indent)
          _ -> spaces(indent) <> "- " <> emit(entry, indent + 2)
        }
      })
      |> string.join(with: "\n")
  }
}

fn emit_nested_sequence_entry(entry: YamlNode, indent: Int) -> String {
  let nested_indent = indent + 2

  case string.split(emit(entry, nested_indent), "\n") {
    [] -> spaces(indent) <> "- "
    [first, ..rest] ->
      [
        spaces(indent) <> "- " <> string.drop_start(first, nested_indent),
        ..rest
      ]
      |> string.join(with: "\n")
  }
}

fn emit_mapping(entries: List(#(YamlNode, YamlNode)), indent: Int) -> String {
  case entries {
    [] -> "{}"
    [_, ..] ->
      entries
      |> list.map(fn(entry) {
        let #(key, value) = entry
        let rendered_key = emit_key(key)
        let rendered_value = emit(value, indent + 2)

        case node.kind(value) {
          node.Mapping([]) | node.Sequence([]) ->
            spaces(indent) <> rendered_key <> ": " <> rendered_value
          node.Mapping(_) | node.Sequence(_) ->
            spaces(indent) <> rendered_key <> ":\n" <> rendered_value
          _ -> spaces(indent) <> rendered_key <> ": " <> rendered_value
        }
      })
      |> string.join(with: "\n")
  }
}

fn emit_key(value: YamlNode) -> String {
  case node.kind(value) {
    node.String(value) -> emit_key_string(value)
    _ -> emit(value, 0)
  }
}

fn emit_string(value: String) -> String {
  case needs_quotes(value) {
    True -> quote(value)
    False -> value
  }
}

fn emit_key_string(value: String) -> String {
  case needs_quotes(value) || string.contains(value, ":") {
    True -> quote(value)
    False -> value
  }
}

fn quote(value: String) -> String {
  value
  |> string.replace(each: "\\", with: "\\\\")
  |> string.replace(each: "\"", with: "\\\"")
  |> string.replace(each: "\n", with: "\\n")
  |> wrap_quotes
}

fn wrap_quotes(value: String) -> String {
  "\"" <> value <> "\""
}

fn needs_quotes(value: String) -> Bool {
  string.is_empty(value)
  || string.trim(value) != value
  || string.contains(value, "\n")
  || string.contains(value, ":")
  || string.contains(value, "#")
  || string.contains(value, "[")
  || string.contains(value, "]")
  || string.contains(value, "{")
  || string.contains(value, "}")
  || string.contains(value, ",")
  || string.contains(value, "\"")
  || plain_scalar_would_change_type(value)
}

fn plain_scalar_would_change_type(value: String) -> Bool {
  case scalar.parse(value) {
    Some(node.String(parsed)) if parsed == value -> False
    _ -> True
  }
}

fn spaces(count: Int) -> String {
  string.repeat(" ", count)
}
