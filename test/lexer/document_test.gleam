import birdie
import gleam/list
import gleam/result
import gleam/string
import nibble/lexer
import yum/yaml/error.{type YamlError}
import yum/yaml/lexer as yum_yaml_lexer
import yum/yaml/token.{type Token}

const test_file_prefix = "lexer:document:"

pub fn explicit_start_document_test() {
  let input = "---\nhello"

  input
  |> yum_yaml_lexer.lex()
  |> snap(input, "explicit_start_document_test")
}

pub fn explicit_end_document_test() {
  let input = "hello\n..."

  input
  |> yum_yaml_lexer.lex()
  |> snap(input, "explicit_end_document_test")
}

pub fn multiple_documents_test() {
  let input = "---\none\n---\ntwo\n...\n---\nthree"

  input
  |> yum_yaml_lexer.lex()
  |> snap(input, "multiple_documents_test")
}

pub fn empty_explicit_document_test() {
  let input = "--- # Empty\n...\n---\nvalue"

  input
  |> yum_yaml_lexer.lex()
  |> snap(input, "empty_explicit_document_test")
}

pub fn marker_like_scalars_test() {
  let input =
    "items:\n- ---not marker\n- ...not marker\nmapping:\n  marker: ---"

  input
  |> yum_yaml_lexer.lex()
  |> snap(input, "marker_like_scalars_test")
}

pub fn markers_around_block_collections_test() {
  let input = "---\n- one\n- two\n...\n---\nkey: value"

  input
  |> yum_yaml_lexer.lex()
  |> snap(input, "markers_around_block_collections_test")
}

fn unwrap_token(result: Result(List(lexer.Token(Token)), YamlError)) {
  use l <- result.try(result)
  l
  |> list.map(fn(token) { token.value })
  |> Ok
}

fn snap(
  tokens: Result(List(lexer.Token(Token)), YamlError),
  input: String,
  title: String,
) {
  assert result.is_ok({
    use unwrapped <- result.try(unwrap_token(tokens))
    let result = string.inspect(unwrapped)

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
