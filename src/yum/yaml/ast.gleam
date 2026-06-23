//// YAML document and AST types.
////
//// [`Yaml`](#Yaml) represents a parsed YAML document. It is opaque so the document shape
//// can grow as more of the YAML stream model is implemented, such as directives
//// and multiple documents.
////
//// [`YamlAST`](#YamlAST) represents the root node tree inside one YAML document. Import this
//// module when you want to pattern match on parsed YAML values or build expected
//// values in tests.
////

pub opaque type Yaml {
  Yaml(ast: YamlAST, directives: List(YamlDirective))
}

pub type YamlDirective {
  YamlDirective(name: String, parameters: List(String))
}

pub type YamlAST {
  Null
  Bool(Bool)
  Int(Int)
  Float(Float)
  PosInf
  NegInf
  Nan
  String(String)
  Sequence(List(YamlAST))
  Mapping(List(#(YamlAST, YamlAST)))
}

/// Creates a YAML document from a single AST node and no directives.
///
pub fn to_yaml(ast: YamlAST) -> Yaml {
  new(ast: ast, directives: [])
}

/// Creates a YAML document from a single AST node and directives.
///
pub fn new(
  ast ast: YamlAST,
  directives directives: List(YamlDirective),
) -> Yaml {
  Yaml(ast: ast, directives: directives)
}

/// Returns the root AST node for a YAML document.
///
pub fn contents(yaml: Yaml) -> YamlAST {
  yaml.ast
}

/// Returns the directives associated with a YAML document.
///
pub fn directives(yaml: Yaml) -> List(YamlDirective) {
  yaml.directives
}
