import birdie
import gleam/result
import gleam/string
import yaml_helpers as helpers

const test_file_prefix = "parser:block_mapping:"

pub fn simple_block_mapping_test() {
  let input = "one: two\nthree: four"

  input
  |> helpers.parse_ast()
  |> snap(input, "simple_block_mapping_test")
}

pub fn omitted_values_block_mapping_test() {
  let input = "empty:\nexplicit null: null\nempty again:"

  input
  |> helpers.parse_ast()
  |> snap(input, "omitted_values_block_mapping_test")
}

pub fn mixed_nodes_block_mapping_test() {
  let input =
    "null: null\ntrue: true\nnumber: 123\nsequence: [one, two]\nmapping: {key: value}\ndouble: \"double quoted\"\nsingle: 'single quoted'"

  input
  |> helpers.parse_ast()
  |> snap(input, "mixed_nodes_block_mapping_test")
}

pub fn nested_collections_block_mapping_test() {
  let input =
    "outer:\n  inner: value\n  list:\n    - one\n    - two\nsibling: done"

  input
  |> helpers.parse_ast()
  |> snap(input, "nested_collections_block_mapping_test")
}

pub fn urls_and_colons_block_mapping_test() {
  let input =
    "url: https://example.com/foo#bar\nhttps://example.com/foo: value\nliteral: not:a key"

  input
  |> helpers.parse_ast()
  |> snap(input, "urls_and_colons_block_mapping_test")
}

pub fn block_sequence_of_block_mappings_test() {
  let input = "-\n  name: Mark\n  hr: 65\n-\n  name: Sammy\n  hr: 63"

  input
  |> helpers.parse_ast()
  |> snap(input, "block_sequence_of_block_mappings_test")
}

pub fn explicit_scalar_key_block_mapping_test() {
  let input = "? name\n: Mark"

  input
  |> helpers.parse_ast()
  |> snap(input, "explicit_scalar_key_block_mapping_test")
}

pub fn explicit_empty_key_block_mapping_test() {
  let input = ": empty key"

  input
  |> helpers.parse_ast()
  |> snap(input, "explicit_empty_key_block_mapping_test")
}

pub fn explicit_flow_collection_key_block_mapping_test() {
  let input = "? [one, two]\n: sequence key"

  input
  |> helpers.parse_ast()
  |> snap(input, "explicit_flow_collection_key_block_mapping_test")
}

pub fn explicit_nested_block_key_block_mapping_test() {
  let input = "?\n  - one\n  - two\n: sequence key"

  input
  |> helpers.parse_ast()
  |> snap(input, "explicit_nested_block_key_block_mapping_test")
}

pub fn explicit_nested_block_value_block_mapping_test() {
  let input = "? key\n:\n  inner: value"

  input
  |> helpers.parse_ast()
  |> snap(input, "explicit_nested_block_value_block_mapping_test")
}

pub fn explicit_compact_sequence_key_and_value_block_mapping_test() {
  let input = "? - Detroit Tigers\n  - Chicago cubs\n: - 2001-07-23"

  input
  |> helpers.parse_ast()
  |> snap(input, "explicit_compact_sequence_key_and_value_block_mapping_test")
}

pub fn implicit_quoted_key_block_mapping_test() {
  let input = "\"quoted key\":\n- entry"

  input
  |> helpers.parse_ast()
  |> snap(input, "implicit_quoted_key_block_mapping_test")
}

pub fn multiple_explicit_entries_block_mapping_test() {
  let input = "? one\n: two\n? three\n: four"

  input
  |> helpers.parse_ast()
  |> snap(input, "multiple_explicit_entries_block_mapping_test")
}

pub fn explicit_block_mapping_key_block_mapping_test() {
  let input = "?\n  left: one\n  right: two\n: mapping key"

  input
  |> helpers.parse_ast()
  |> snap(input, "explicit_block_mapping_key_block_mapping_test")
}

pub fn nested_explicit_block_mapping_value_test() {
  let input = "outer:\n  ? inner\n  : value\n  sibling: ok"

  input
  |> helpers.parse_ast()
  |> snap(input, "nested_explicit_block_mapping_value_test")
}

pub fn explicit_value_is_explicit_block_mapping_test() {
  let input = "? outer\n:\n  ? inner\n  : value"

  input
  |> helpers.parse_ast()
  |> snap(input, "explicit_value_is_explicit_block_mapping_test")
}

pub fn explicit_flow_mapping_key_nested_value_test() {
  let input = "? {left: [one, two], right: {nested: yes}}\n:\n  result: ok"

  input
  |> helpers.parse_ast()
  |> snap(input, "explicit_flow_mapping_key_nested_value_test")
}

pub fn null_key_with_nested_explicit_mapping_value_test() {
  let input = ":\n  ? nested key\n  : nested value"

  input
  |> helpers.parse_ast()
  |> snap(input, "null_key_with_nested_explicit_mapping_value_test")
}

pub fn explicit_null_value_before_next_entry_test() {
  let input = "? lonely\nnext: value"

  input
  |> helpers.parse_ast()
  |> snap(input, "explicit_null_value_before_next_entry_test")
}

pub fn sequence_with_nested_explicit_mappings_test() {
  let input = "- ? name\n  : Mark\n- ?\n    role: hitter\n  : active"

  input
  |> helpers.parse_ast()
  |> snap(input, "sequence_with_nested_explicit_mappings_test")
}

fn snap(parsed: _, input: String, title: String) {
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
