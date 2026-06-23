import gleam/dynamic
import gleam/list
import yum/yaml/node.{type Node}

pub fn from_node(value: Node) -> dynamic.Dynamic {
  case node.kind(value) {
    node.Null -> dynamic.nil()
    node.Bool(value) -> dynamic.bool(value)
    node.Int(value) -> dynamic.int(value)
    node.Float(value) -> dynamic.float(value)
    node.PosInf -> dynamic.string(".inf")
    node.NegInf -> dynamic.string("-.inf")
    node.Nan -> dynamic.string(".nan")
    node.String(value) -> dynamic.string(value)
    node.Sequence(entries) ->
      entries
      |> list.map(from_node)
      |> dynamic.array
    node.Mapping(entries) ->
      entries
      |> list.map(fn(entry) {
        let #(key, value) = entry
        #(from_node(key), from_node(value))
      })
      |> dynamic.properties
  }
}
