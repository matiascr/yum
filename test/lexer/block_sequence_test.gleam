import birdie
import gleam/list
import gleam/result
import gleam/string
import nibble/lexer
import yum/yaml/error.{type YamlError}
import yum/yaml/lexer as yum_yaml_lexer
import yum/yaml/token.{type Token}

const test_file_prefix = "lexer:block_sequence:"

pub fn simple_block_sequence_test() {
  let input = "- one\n- two\n- three"

  input
  |> yum_yaml_lexer.lex()
  |> snap(input, "simple_block_sequence_test")
}

pub fn trailing_line_break_block_sequence_test() {
  let input = "- one\n- two\n"

  input
  |> yum_yaml_lexer.lex()
  |> snap(input, "trailing_line_break_block_sequence_test")
}

pub fn blank_lines_block_sequence_test() {
  let input = "- one\n\n- two\n\n\n- three"

  input
  |> yum_yaml_lexer.lex()
  |> snap(input, "blank_lines_block_sequence_test")
}

pub fn empty_entries_block_sequence_test() {
  let input = "-\n- two\n-"

  input
  |> yum_yaml_lexer.lex()
  |> snap(input, "empty_entries_block_sequence_test")
}

pub fn nested_block_sequence_test() {
  let input = "-\n  - one\n  - two\n- three"

  input
  |> yum_yaml_lexer.lex()
  |> snap(input, "nested_block_sequence_test")
}

pub fn mixed_nodes_block_sequence_test() {
  let input =
    "- null\n- true\n- 123\n- [one, two]\n- {key: value}\n- \"double quoted\"\n- 'single quoted'"

  input
  |> yum_yaml_lexer.lex()
  |> snap(input, "mixed_nodes_block_sequence_test")
}

pub fn dash_inside_scalar_block_sequence_test() {
  let input = "- one-two\n- --not an entry marker"

  input
  |> yum_yaml_lexer.lex()
  |> snap(input, "dash_inside_scalar_block_sequence_test")
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
