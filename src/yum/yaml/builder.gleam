//// Build YAML nodes in Gleam code.
////
//// The functions in this module create synthetic [`Node`](./node.html#Node)
//// values. Pass the root node to [`yum/yaml.from_node`](../yaml.html#from_node)
//// when you want to emit it as YAML or use it with the rest of the public YAML
//// API.
////
//// ```gleam
//// import yum/yaml
//// import yum/yaml/builder
////
//// pub fn example() {
////   let document =
////     builder.mapping([
////       #(builder.string("name"), builder.string("yum")),
////       #(
////         builder.string("commands"),
////         builder.sequence([
////           builder.string("gleam test"),
////           builder.string("gleam format"),
////         ]),
////       ),
////     ])
////     |> yaml.from_node()
////
////   let output = yaml.to_string(document)
////
////   assert output ==
//// "name: yum
//// commands:
////   - gleam test
////   - gleam format"
//// }
//// ```

import yum/yaml/node.{type Node}

/// Builds a YAML null node.
///
pub fn null() -> Node {
  node.synthetic(node.Null)
}

/// Builds a YAML boolean node.
///
pub fn bool(value: Bool) -> Node {
  node.synthetic(node.Bool(value))
}

/// Builds a YAML integer node.
///
pub fn int(value: Int) -> Node {
  node.synthetic(node.Int(value))
}

/// Builds a YAML floating-point node.
///
/// YAML's special float values are represented as separate node kinds. Use
/// [`node.synthetic`](./node.html#synthetic) with [`node.PosInf`](./node.html#Kind),
/// [`node.NegInf`](./node.html#Kind), or [`node.Nan`](./node.html#Kind) for
/// those values.
pub fn float(value: Float) -> Node {
  node.synthetic(node.Float(value))
}

/// Builds a YAML string node.
///
pub fn string(value: String) -> Node {
  node.synthetic(node.String(value))
}

/// Builds a YAML sequence node from already-built nodes.
///
pub fn sequence(entries: List(Node)) -> Node {
  node.synthetic(node.Sequence(entries))
}

/// Builds a YAML mapping node from already-built key/value node pairs.
///
pub fn mapping(entries: List(#(Node, Node))) -> Node {
  node.synthetic(node.Mapping(entries))
}
