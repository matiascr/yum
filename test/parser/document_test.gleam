import birdie
import gleam/result
import gleam/string
import yum/yaml
import yum/yaml/error

const test_file_prefix = "parser:document:"

pub fn explicit_start_document_test() {
  let input = "---\nhello"

  input
  |> yaml.parse_ast()
  |> snap(input, "explicit_start_document_test")
}

pub fn explicit_end_document_test() {
  let input = "hello\n..."

  input
  |> yaml.parse_ast()
  |> snap(input, "explicit_end_document_test")
}

pub fn multiple_documents_test() {
  let input = "---\none\n---\ntwo\n...\n---\nthree"

  input
  |> yaml.parse_ast_stream()
  |> snap(input, "multiple_documents_test")
}

pub fn empty_explicit_document_test() {
  let input = "--- # Empty\n...\n---\nvalue"

  input
  |> yaml.parse_ast_stream()
  |> snap(input, "empty_explicit_document_test")
}

pub fn end_marker_before_bare_document_test() {
  let input = "one\n...\ntwo"

  input
  |> yaml.parse_ast_stream()
  |> snap(input, "end_marker_before_bare_document_test")
}

pub fn marker_like_scalars_test() {
  let input =
    "items:\n- ---not marker\n- ...not marker\nmapping:\n  marker: ---"

  input
  |> yaml.parse_ast()
  |> snap(input, "marker_like_scalars_test")
}

pub fn markers_around_block_collections_test() {
  let input = "---\n- one\n- two\n...\n---\nkey: value"

  input
  |> yaml.parse_ast_stream()
  |> snap(input, "markers_around_block_collections_test")
}

pub fn single_document_api_rejects_multiple_documents_test() {
  assert yaml.parse_ast("---\none\n---\ntwo") == Error(error.MultipleDocuments)
}

pub fn stream_rejects_unmarked_second_document_test() {
  assert yaml.parse_ast_stream("one\nkey: value") |> result.is_error()
}

fn snap(parsed: Result(a, error.YamlError), input: String, title: String) {
  assert result.is_ok({
    use yaml <- result.try(parsed)
    let result = string.inspect(yaml)

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
