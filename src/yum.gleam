//// Compatibility entry point for parsing YAML.
////
//// Prefer importing [`yum/yaml`](./yum/yaml.html) in new code. This module keeps [`yum.parse`](./yum/yaml.html#parse)
//// available as a small forwarding wrapper.
////

import yum/yaml
import yum/yaml/ast.{type Yaml}
import yum/yaml/error.{type YamlError}

/// Parses a YAML file into a YAML document.
///
/// Follows the [YAML 1.2 specification](https://yaml.org/spec/1.2.2/)
///
pub fn parse(input: String) -> Result(Yaml, YamlError) {
  yaml.parse(input)
}

/// Parses a YAML stream into a list of YAML documents.
///
pub fn parse_stream(input: String) -> Result(List(Yaml), YamlError) {
  yaml.parse_stream(input)
}
