//// Parsed YAML documents.
////
//// A document contains the root YAML node plus document-level metadata such as
//// directives. Use `yum/yaml.parse_document` when tooling needs this metadata.

import yum/yaml/node.{type Span, type YamlNode}

pub opaque type Document {
  Document(root: YamlNode, directives: List(Directive))
}

pub type Directive {
  Directive(name: String, parameters: List(String), span: Span)
}

pub fn new(root root: YamlNode, directives directives: List(Directive)) {
  Document(root:, directives:)
}

pub fn root(document: Document) -> YamlNode {
  document.root
}

pub fn directives(document: Document) -> List(Directive) {
  document.directives
}
