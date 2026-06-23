import yaml_ast
import yaml_helpers as helpers
import yum/yaml

pub fn parse_returns_raw_yaml_document_test() {
  let assert Ok(document) = yaml.parse("hello")

  assert document |> yaml.root() |> helpers.to_ast() == yaml_ast.String("hello")
  assert yaml.directives(document) == []
}

pub fn parse_stream_returns_raw_yaml_documents_test() {
  let assert Ok([one, two]) = yaml.parse_stream("---\none\n---\ntwo")

  assert one |> yaml.root() |> helpers.to_ast() == yaml_ast.String("one")
  assert yaml.directives(one) == []
  assert two |> yaml.root() |> helpers.to_ast() == yaml_ast.String("two")
  assert yaml.directives(two) == []
}
