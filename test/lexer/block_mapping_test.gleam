import birdie
import gleam/list
import gleam/result
import gleam/string
import nibble/lexer
import yum/yaml/error.{type YamlError}
import yum/yaml/lexer as yum_yaml_lexer
import yum/yaml/token.{type Token}

const test_file_prefix = "lexer:block_mapping:"

pub fn simple_block_mapping_test() {
  let input = "one: two\nthree: four"

  input
  |> yum_yaml_lexer.lex()
  |> snap(input, "simple_block_mapping_test")
}

pub fn omitted_values_block_mapping_test() {
  let input = "empty:\nexplicit null: null\nempty again:"

  input
  |> yum_yaml_lexer.lex()
  |> snap(input, "omitted_values_block_mapping_test")
}

pub fn mixed_nodes_block_mapping_test() {
  let input =
    "null: null\ntrue: true\nnumber: 123\nsequence: [one, two]\nmapping: {key: value}\ndouble: \"double quoted\"\nsingle: 'single quoted'"

  input
  |> yum_yaml_lexer.lex()
  |> snap(input, "mixed_nodes_block_mapping_test")
}

pub fn nested_collections_block_mapping_test() {
  let input =
    "outer:\n  inner: value\n  list:\n    - one\n    - two\nsibling: done"

  input
  |> yum_yaml_lexer.lex()
  |> snap(input, "nested_collections_block_mapping_test")
}

pub fn urls_and_colons_block_mapping_test() {
  let input =
    "url: https://example.com/foo#bar\nhttps://example.com/foo: value\nliteral: not:a key"

  input
  |> yum_yaml_lexer.lex()
  |> snap(input, "urls_and_colons_block_mapping_test")
}

pub fn block_sequence_of_block_mappings_test() {
  let input = "-\n  name: Mark\n  hr: 65\n-\n  name: Sammy\n  hr: 63"

  input
  |> yum_yaml_lexer.lex()
  |> snap(input, "block_sequence_of_block_mappings_test")
}

pub fn explicit_scalar_key_block_mapping_test() {
  let input = "? name\n: Mark"

  input
  |> yum_yaml_lexer.lex()
  |> snap(input, "explicit_scalar_key_block_mapping_test")
}

pub fn explicit_empty_key_block_mapping_test() {
  let input = ": empty key"

  input
  |> yum_yaml_lexer.lex()
  |> snap(input, "explicit_empty_key_block_mapping_test")
}

pub fn explicit_flow_collection_key_block_mapping_test() {
  let input = "? [one, two]\n: sequence key"

  input
  |> yum_yaml_lexer.lex()
  |> snap(input, "explicit_flow_collection_key_block_mapping_test")
}

pub fn explicit_nested_block_key_block_mapping_test() {
  let input = "?\n  - one\n  - two\n: sequence key"

  input
  |> yum_yaml_lexer.lex()
  |> snap(input, "explicit_nested_block_key_block_mapping_test")
}

pub fn explicit_nested_block_value_block_mapping_test() {
  let input = "? key\n:\n  inner: value"

  input
  |> yum_yaml_lexer.lex()
  |> snap(input, "explicit_nested_block_value_block_mapping_test")
}

pub fn explicit_compact_sequence_key_and_value_block_mapping_test() {
  let input = "? - Detroit Tigers\n  - Chicago cubs\n: - 2001-07-23"

  input
  |> yum_yaml_lexer.lex()
  |> snap(input, "explicit_compact_sequence_key_and_value_block_mapping_test")
}

pub fn implicit_quoted_key_block_mapping_test() {
  let input = "\"quoted key\":\n- entry"

  input
  |> yum_yaml_lexer.lex()
  |> snap(input, "implicit_quoted_key_block_mapping_test")
}

pub fn multiple_explicit_entries_block_mapping_test() {
  let input = "? one\n: two\n? three\n: four"

  input
  |> yum_yaml_lexer.lex()
  |> snap(input, "multiple_explicit_entries_block_mapping_test")
}

pub fn explicit_block_mapping_key_block_mapping_test() {
  let input = "?\n  left: one\n  right: two\n: mapping key"

  input
  |> yum_yaml_lexer.lex()
  |> snap(input, "explicit_block_mapping_key_block_mapping_test")
}

pub fn nested_explicit_block_mapping_value_test() {
  let input = "outer:\n  ? inner\n  : value\n  sibling: ok"

  input
  |> yum_yaml_lexer.lex()
  |> snap(input, "nested_explicit_block_mapping_value_test")
}

pub fn explicit_value_is_explicit_block_mapping_test() {
  let input = "? outer\n:\n  ? inner\n  : value"

  input
  |> yum_yaml_lexer.lex()
  |> snap(input, "explicit_value_is_explicit_block_mapping_test")
}

pub fn explicit_flow_mapping_key_nested_value_test() {
  let input = "? {left: [one, two], right: {nested: yes}}\n:\n  result: ok"

  input
  |> yum_yaml_lexer.lex()
  |> snap(input, "explicit_flow_mapping_key_nested_value_test")
}

pub fn null_key_with_nested_explicit_mapping_value_test() {
  let input = ":\n  ? nested key\n  : nested value"

  input
  |> yum_yaml_lexer.lex()
  |> snap(input, "null_key_with_nested_explicit_mapping_value_test")
}

pub fn explicit_null_value_before_next_entry_test() {
  let input = "? lonely\nnext: value"

  input
  |> yum_yaml_lexer.lex()
  |> snap(input, "explicit_null_value_before_next_entry_test")
}

pub fn sequence_with_nested_explicit_mappings_test() {
  let input = "- ? name\n  : Mark\n- ?\n    role: hitter\n  : active"

  input
  |> yum_yaml_lexer.lex()
  |> snap(input, "sequence_with_nested_explicit_mappings_test")
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
