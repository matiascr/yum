import birdie
import gleam/list
import gleam/result
import gleam/string
import nibble/lexer
import yaml/error.{type YamlError}
import yaml/lexer as yaml_lexer
import yaml/token.{type Token}

const test_file_prefix = "lexer:flow_mapping:"

pub fn empty_flow_mapping_test() {
  let input = "{}"

  input
  |> yaml_lexer.lex()
  |> snap(input, "empty_flow_mapping_test")
}

pub fn simple_flow_mapping_test() {
  let input = "{one: two, three: four}"

  input
  |> yaml_lexer.lex()
  |> snap(input, "simple_flow_mapping_test")
}

pub fn whitespace_and_trailing_comma_flow_mapping_test() {
  let input = "{ one : two , three: four , }"

  input
  |> yaml_lexer.lex()
  |> snap(input, "whitespace_and_trailing_comma_flow_mapping_test")
}

pub fn omitted_key_and_value_flow_mapping_test() {
  let input = "{omitted value:, : omitted key, solo}"

  input
  |> yaml_lexer.lex()
  |> snap(input, "omitted_key_and_value_flow_mapping_test")
}

pub fn explicit_entries_flow_mapping_test() {
  let input = "{? explicit: entry, implicit: entry, ?}"

  input
  |> yaml_lexer.lex()
  |> snap(input, "explicit_entries_flow_mapping_test")
}

pub fn adjacent_values_flow_mapping_test() {
  let input = "{adjacent :value, readable: value, empty:}"

  input
  |> yaml_lexer.lex()
  |> snap(input, "adjacent_values_flow_mapping_test")
}

pub fn quoted_adjacent_values_flow_mapping_test() {
  let input = "{\"adjacent\":value, \"readable\": value, \"empty\":}"

  input
  |> yaml_lexer.lex()
  |> snap(input, "quoted_adjacent_values_flow_mapping_test")
}

pub fn url_plain_key_flow_mapping_test() {
  let input = "{https://foo.com, other: value}"

  input
  |> yaml_lexer.lex()
  |> snap(input, "url_plain_key_flow_mapping_test")
}

pub fn nested_collections_flow_mapping_test() {
  let input = "{seq: [one, two], map: {inner: value}}"

  input
  |> yaml_lexer.lex()
  |> snap(input, "nested_collections_flow_mapping_test")
}

pub fn compact_mapping_in_sequence_test() {
  let input = "[foo: bar, {JSON: like}:adjacent]"

  input
  |> yaml_lexer.lex()
  |> snap(input, "compact_mapping_in_sequence_test")
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
