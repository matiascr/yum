import birdie
import gleam/list
import gleam/result
import gleam/string
import nibble/lexer
import yaml/error.{type YamlError}
import yaml/lexer as yaml_lexer
import yaml/token.{type Token}

const test_file_prefix = "lexer:flow_sequence:"

pub fn empty_flow_sequence_test() {
  let input = "[]"

  input
  |> yaml_lexer.lex()
  |> snap(input, "empty_flow_sequence_test")
}

pub fn simple_flow_sequence_test() {
  let input = "[one, two, three]"

  input
  |> yaml_lexer.lex()
  |> snap(input, "simple_flow_sequence_test")
}

pub fn trailing_comma_flow_sequence_test() {
  let input = "[one, two,]"

  input
  |> yaml_lexer.lex()
  |> snap(input, "trailing_comma_flow_sequence_test")
}

pub fn adjacent_entries_flow_sequence_test() {
  let input = "[one,two,three]"

  input
  |> yaml_lexer.lex()
  |> snap(input, "adjacent_entries_flow_sequence_test")
}

pub fn mixed_primitives_flow_sequence_test() {
  let input = "[null, true, false, 123, 1.5, .nan]"

  input
  |> yaml_lexer.lex()
  |> snap(input, "mixed_primitives_flow_sequence_test")
}

pub fn quoted_entries_flow_sequence_test() {
  let input = "[\"double quoted\", 'single ''quoted''']"

  input
  |> yaml_lexer.lex()
  |> snap(input, "quoted_entries_flow_sequence_test")
}

pub fn multiline_entries_flow_sequence_test() {
  let input = "[\"double\n quoted\", 'single\n quoted', plain\n text]"

  input
  |> yaml_lexer.lex()
  |> snap(input, "multiline_entries_flow_sequence_test")
}

pub fn nested_flow_sequence_test() {
  let input = "[one, [two, three], four]"

  input
  |> yaml_lexer.lex()
  |> snap(input, "nested_flow_sequence_test")
}

pub fn nested_empty_flow_sequence_test() {
  let input = "[[], [one], []]"

  input
  |> yaml_lexer.lex()
  |> snap(input, "nested_empty_flow_sequence_test")
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
      "Input:\n\n"
      <> string.inspect(input)
      <> "\n\n"
      <> string.repeat("-", 71)
      <> "\n\n```gleam\n"
      <> result
      <> "\n\n```"

    snap_contents
    |> birdie.snap(test_file_prefix <> title)
    |> Ok
  })
}
