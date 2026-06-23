import birdie
import gleam/result
import gleam/string
import yaml_ast.{type YamlAST}
import yaml_helpers as helpers
import yaml_render
import yum/yaml
import yum/yaml/error
import yum/yaml/node

const test_file_prefix = "parser:document:"

pub fn explicit_start_document_test() {
  let input = "---\nhello"

  input
  |> helpers.parse_ast()
  |> snap(input, "explicit_start_document_test")
}

pub fn explicit_end_document_test() {
  let input = "hello\n..."

  input
  |> helpers.parse_ast()
  |> snap(input, "explicit_end_document_test")
}

pub fn multiple_documents_test() {
  let input = "---\none\n---\ntwo\n...\n---\nthree"

  input
  |> helpers.parse_ast_stream()
  |> snap_stream(input, "multiple_documents_test")
}

pub fn empty_explicit_document_test() {
  let input = "--- # Empty\n...\n---\nvalue"

  input
  |> helpers.parse_ast_stream()
  |> snap_stream(input, "empty_explicit_document_test")
}

pub fn end_marker_before_bare_document_test() {
  let input = "one\n...\ntwo"

  input
  |> helpers.parse_ast_stream()
  |> snap_stream(input, "end_marker_before_bare_document_test")
}

pub fn marker_like_scalars_test() {
  let input =
    "items:\n- ---not marker\n- ...not marker\nmapping:\n  marker: ---"

  input
  |> helpers.parse_ast()
  |> snap(input, "marker_like_scalars_test")
}

pub fn markers_around_block_collections_test() {
  let input = "---\n- one\n- two\n...\n---\nkey: value"

  input
  |> helpers.parse_ast_stream()
  |> snap_stream(input, "markers_around_block_collections_test")
}

pub fn parse_document_preserves_yaml_directive_test() {
  let assert Ok(parsed) = yaml.parse("%YAML 1.2\n---\nhello\n")

  assert yaml.directives(parsed)
    == [
      yaml.Directive(
        name: "YAML",
        parameters: ["1.2"],
        span: node.Span(start: node.Position(1, 1), end: node.Position(1, 10)),
      ),
    ]
}

pub fn parse_document_preserves_tag_directive_test() {
  let assert Ok(parsed) =
    yaml.parse("%TAG !e! tag:example.com,2026:\n---\n!e!thing value\n")

  assert yaml.directives(parsed)
    == [
      yaml.Directive(
        name: "TAG",
        parameters: ["!e!", "tag:example.com,2026:"],
        span: node.Span(start: node.Position(1, 1), end: node.Position(1, 31)),
      ),
    ]
}

pub fn parse_preserves_directives_on_yaml_document_test() {
  let assert Ok(parsed) = yaml.parse("%YAML 1.2\n---\nhello\n")

  assert yaml.directives(parsed)
    == [
      yaml.Directive(
        name: "YAML",
        parameters: ["1.2"],
        span: node.Span(start: node.Position(1, 1), end: node.Position(1, 10)),
      ),
    ]
}

pub fn document_root_ignores_directives_test() {
  let assert Ok(parsed) = helpers.parse_node("%YAML 1.2\n---\nhello\n")

  assert node.as_string(parsed) == Ok("hello")
}

pub fn directives_require_explicit_document_start_test() {
  assert yaml.parse("%YAML 1.2\nhello\n") |> result.is_error()
}

pub fn single_document_api_rejects_multiple_documents_test() {
  assert helpers.parse_ast("---\none\n---\ntwo")
    == Error(error.MultipleDocuments)
}

pub fn stream_rejects_unmarked_second_document_test() {
  assert helpers.parse_ast_stream("one\nkey: value") |> result.is_error()
}

fn snap(
  parsed: Result(YamlAST, error.YamlError),
  input: String,
  title: String,
) {
  assert result.is_ok({
    use yaml <- result.try(parsed)
    let result = yaml_render.ast(yaml)

    let snap_contents =
      "Input:\n\n```yaml\n"
      <> input
      <> "\n```\n\n"
      <> string.repeat("-", 71)
      <> "\n\n```gleam\n"
      <> result
      <> "\n\n```"

    snap_contents
    |> birdie.snap(test_file_prefix <> title)
    |> Ok
  })
}

fn snap_stream(
  parsed: Result(List(YamlAST), error.YamlError),
  input: String,
  title: String,
) {
  assert result.is_ok({
    use yaml <- result.try(parsed)
    let result = yaml_render.asts(yaml)

    let snap_contents =
      "Input:\n\n```yaml\n"
      <> input
      <> "\n```\n\n"
      <> string.repeat("-", 71)
      <> "\n\n```gleam\n"
      <> result
      <> "\n\n```"

    snap_contents
    |> birdie.snap(test_file_prefix <> title)
    |> Ok
  })
}
