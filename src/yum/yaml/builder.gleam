//// Builders for YAML nodes.

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
