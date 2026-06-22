import yum/yaml
import yum/yaml/ast as yaml_ast

pub fn parse_wraps_ast_in_document_test() {
  let assert Ok(document) = yaml.parse("hello")

  assert yaml_ast.contents(document) == yaml_ast.String("hello")
  assert yaml_ast.directives(document) == []
}
