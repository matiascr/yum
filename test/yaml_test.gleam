import yum/yaml
import yum/yaml/ast as yaml_ast

pub fn parse_wraps_ast_in_document_test() {
  let assert Ok(document) = yaml.parse("hello")

  assert yaml_ast.contents(document) == yaml_ast.String("hello")
  assert yaml_ast.directives(document) == []
}

pub fn parse_stream_wraps_each_ast_in_document_test() {
  let assert Ok([one, two]) = yaml.parse_stream("---\none\n---\ntwo")

  assert yaml_ast.contents(one) == yaml_ast.String("one")
  assert yaml_ast.directives(one) == []
  assert yaml_ast.contents(two) == yaml_ast.String("two")
  assert yaml_ast.directives(two) == []
}
