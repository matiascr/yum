import birdie
import gleam/list
import gleam/result
import gleam/string
import nibble/lexer
import yum/yaml/error.{type YamlError}
import yum/yaml/lexer as yum_yaml_lexer
import yum/yaml/token.{type Token}

const test_file_prefix = "lexer:block_scalar:"

pub fn literal_clip_block_scalar_test() {
  let input = "|\n  line one\n  line two\n"

  input
  |> yum_yaml_lexer.lex()
  |> snap(input, "literal_clip_block_scalar_test")
}

pub fn literal_strip_block_scalar_test() {
  let input = "|-\n  line one\n  line two\n"

  input
  |> yum_yaml_lexer.lex()
  |> snap(input, "literal_strip_block_scalar_test")
}

pub fn literal_keep_block_scalar_test() {
  let input = "|+\n  line one\n  line two\n\n"

  input
  |> yum_yaml_lexer.lex()
  |> snap(input, "literal_keep_block_scalar_test")
}

pub fn folded_clip_block_scalar_test() {
  let input = ">\n  line one\n  line two\n\n  line four\n"

  input
  |> yum_yaml_lexer.lex()
  |> snap(input, "folded_clip_block_scalar_test")
}

pub fn nested_mapping_block_scalar_test() {
  let input = "outer:\n  literal: |\n    line one\n    line two\n  next: value"

  input
  |> yum_yaml_lexer.lex()
  |> snap(input, "nested_mapping_block_scalar_test")
}

pub fn sequence_block_scalar_test() {
  let input = "- |\n  first\n  second\n- >-\n  third\n  fourth"

  input
  |> yum_yaml_lexer.lex()
  |> snap(input, "sequence_block_scalar_test")
}

pub fn preserves_extra_indentation_block_scalar_test() {
  let input = "|\n  line one\n    indented\n  line three\n"

  input
  |> yum_yaml_lexer.lex()
  |> snap(input, "preserves_extra_indentation_block_scalar_test")
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
