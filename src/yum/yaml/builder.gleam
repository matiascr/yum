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

pub fn null() -> Node {
  node.synthetic(node.Null)
}

pub fn bool(value: Bool) -> Node {
  node.synthetic(node.Bool(value))
}

pub fn int(value: Int) -> Node {
  node.synthetic(node.Int(value))
}

pub fn float(value: Float) -> Node {
  node.synthetic(node.Float(value))
}

pub fn string(value: String) -> Node {
  node.synthetic(node.String(value))
}

pub fn sequence(entries: List(Node)) -> Node {
  node.synthetic(node.Sequence(entries))
}

pub fn mapping(entries: List(#(Node, Node))) -> Node {
  node.synthetic(node.Mapping(entries))
}
