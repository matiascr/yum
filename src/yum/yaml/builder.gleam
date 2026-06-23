//// Builders for YAML nodes.

import yum/yaml/node.{type YamlNode}

pub fn null() -> YamlNode {
  node.synthetic(node.Null)
}

pub fn bool(value: Bool) -> YamlNode {
  node.synthetic(node.Bool(value))
}

pub fn int(value: Int) -> YamlNode {
  node.synthetic(node.Int(value))
}

pub fn float(value: Float) -> YamlNode {
  node.synthetic(node.Float(value))
}

pub fn string(value: String) -> YamlNode {
  node.synthetic(node.String(value))
}

pub fn sequence(entries: List(YamlNode)) -> YamlNode {
  node.synthetic(node.Sequence(entries))
}

pub fn mapping(entries: List(#(YamlNode, YamlNode))) -> YamlNode {
  node.synthetic(node.Mapping(entries))
}
