import gleam/float
import gleam/int
import gleam/list
import gleam/string
import yum/yaml/node

pub fn to_string(value: node.YamlNode) -> String {
  emit(value, 0)
}

fn emit(value: node.YamlNode, indent: Int) -> String {
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

fn emit_sequence(entries: List(node.YamlNode), indent: Int) -> String {
  case entries {
    [] -> "[]"
    [_, ..] ->
      entries
      |> list.map(fn(entry) {
        let nested_indent = indent + 2
        case node.kind(entry) {
          node.Mapping(_) | node.Sequence(_) ->
            spaces(indent) <> "- " <> emit(entry, nested_indent)
          _ -> spaces(indent) <> "- " <> emit(entry, nested_indent)
        }
      })
      |> string.join(with: "\n")
  }
}

fn emit_mapping(
  entries: List(#(node.YamlNode, node.YamlNode)),
  indent: Int,
) -> String {
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

fn emit_key(value: node.YamlNode) -> String {
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
  || string.contains(value, "\n")
  || string.contains(value, "#")
  || string.contains(value, "[")
  || string.contains(value, "]")
  || string.contains(value, "{")
  || string.contains(value, "}")
  || string.contains(value, ",")
  || string.contains(value, "\"")
  || is_reserved_plain_scalar(value)
}

fn is_reserved_plain_scalar(value: String) -> Bool {
  case value {
    "null"
    | "Null"
    | "NULL"
    | "~"
    | "true"
    | "True"
    | "TRUE"
    | "false"
    | "False"
    | "FALSE" -> True
    _ -> False
  }
}

fn spaces(count: Int) -> String {
  string.repeat(" ", count)
}
