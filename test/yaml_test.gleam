import gleam/list
import yaml_ast
import yaml_helpers as helpers
import yum/yaml
import yum/yaml/node

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

pub fn get_keys_and_values_return_root_mapping_parts_test() {
  let assert Ok(document) = yaml.parse("name: yum\nlanguage: gleam\n")
  let assert Ok(keys) = yaml.get_keys(document)
  let assert Ok(values) = yaml.get_values(document)

  assert list.map(keys, node.as_string) == [Ok("name"), Ok("language")]
  assert list.map(values, node.as_string) == [Ok("yum"), Ok("gleam")]
}

pub fn get_keys_and_values_require_root_mapping_test() {
  let assert Ok(document) = yaml.parse("- one\n")
  let assert Error(node.ExpectedKind(expected:, found:, span: _)) =
    yaml.get_keys(document)

  assert expected == node.MappingKind
  assert found == node.SequenceKind
}
