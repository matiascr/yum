import birdie
import gleam/list
import gleam/result
import gleam/string
import nibble/lexer
import yaml/error.{type YamlError}
import yaml/lexer as yaml_lexer
import yaml/token.{type Token}

const test_file_prefix = "lexer:block_mapping:"

pub fn simple_block_mapping_test() {
  let input = "one: two\nthree: four"

  input
  |> yaml_lexer.lex()
  |> snap(input, "simple_block_mapping_test")
}

pub fn omitted_values_block_mapping_test() {
  let input = "empty:\nexplicit null: null\nempty again:"

  input
  |> yaml_lexer.lex()
  |> snap(input, "omitted_values_block_mapping_test")
}

pub fn mixed_nodes_block_mapping_test() {
  let input =
    "null: null\ntrue: true\nnumber: 123\nsequence: [one, two]\nmapping: {key: value}\ndouble: \"double quoted\"\nsingle: 'single quoted'"

  input
  |> yaml_lexer.lex()
  |> snap(input, "mixed_nodes_block_mapping_test")
}

pub fn nested_collections_block_mapping_test() {
  let input =
    "outer:\n  inner: value\n  list:\n    - one\n    - two\nsibling: done"

  input
  |> yaml_lexer.lex()
  |> snap(input, "nested_collections_block_mapping_test")
}

pub fn urls_and_colons_block_mapping_test() {
  let input =
    "url: https://example.com/foo#bar\nhttps://example.com/foo: value\nliteral: not:a key"

  input
  |> yaml_lexer.lex()
  |> snap(input, "urls_and_colons_block_mapping_test")
}

pub fn block_sequence_of_block_mappings_test() {
  let input = "-\n  name: Mark\n  hr: 65\n-\n  name: Sammy\n  hr: 63"

  input
  |> yaml_lexer.lex()
  |> snap(input, "block_sequence_of_block_mappings_test")
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
