//// Builders for YAML nodes.

import yum/yaml/node

pub fn null() -> node.YamlNode {
  node.synthetic(node.Null)
}

pub fn bool(value: Bool) -> node.YamlNode {
  node.synthetic(node.Bool(value))
}

pub fn int(value: Int) -> node.YamlNode {
  node.synthetic(node.Int(value))
}

pub fn float(value: Float) -> node.YamlNode {
  node.synthetic(node.Float(value))
}

pub fn string(value: String) -> node.YamlNode {
  node.synthetic(node.String(value))
}

pub fn sequence(entries: List(node.YamlNode)) -> node.YamlNode {
  node.synthetic(node.Sequence(entries))
}

pub fn mapping(
  entries: List(#(node.YamlNode, node.YamlNode)),
) -> node.YamlNode {
  node.synthetic(node.Mapping(entries))
}
