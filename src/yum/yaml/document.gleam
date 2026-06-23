//// Parser document internals.
////
//// Most callers should use the opaque [`yum/yaml.Yaml`](../yaml.html#Yaml)
//// type. This module contains the parser's document representation before it
//// is wrapped in the public raw/resolved YAML API.

import yum/yaml/node.{type Node, type Span}

pub opaque type Document {
  Document(root: Node, directives: List(Directive))
}

/// A YAML directive from the beginning of a document.
///
/// Directives are preserved for tooling and semantic resolution. For example,
/// a TAG directive contributes a tag handle that resolution can use.
pub type Directive {
  /// The directive name, its whitespace-separated parameters, and source span.
  Directive(name: String, parameters: List(String), span: Span)
}

pub fn new(root root: Node, directives directives: List(Directive)) {
  Document(root:, directives:)
}

pub fn root(document: Document) -> Node {
  document.root
}

pub fn directives(document: Document) -> List(Directive) {
  document.directives
}
