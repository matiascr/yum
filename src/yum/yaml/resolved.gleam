//// Resolved YAML documents.
////
//// A resolved document has passed YAML composition checks. Non-fatal warnings
//// are preserved as typed diagnostics so tooling can report them with source
//// spans.

import yum/yaml/diagnostic.{type Diagnostic}
import yum/yaml/node.{type YamlNode}

pub opaque type Resolved {
  Resolved(root: YamlNode, diagnostics: List(Diagnostic))
}

/// Creates a resolved YAML document.
///
/// Most callers should prefer `yum/yaml.resolve`.
///
pub fn new(root root: YamlNode, diagnostics diagnostics: List(Diagnostic)) {
  Resolved(root:, diagnostics:)
}

/// Returns the resolved document root.
///
pub fn root(resolved: Resolved) -> YamlNode {
  resolved.root
}

/// Returns non-fatal diagnostics collected while resolving the document.
///
pub fn diagnostics(resolved: Resolved) -> List(Diagnostic) {
  resolved.diagnostics
}
