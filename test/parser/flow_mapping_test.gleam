import birdie
import gleam/result
import gleam/string
import yum/yaml

const test_file_prefix = "parser:flow_mapping:"

pub fn empty_flow_mapping_test() {
  let input = "{}"

  input
  |> yaml.parse_ast()
  |> snap(input, "empty_flow_mapping_test")
}

pub fn simple_flow_mapping_test() {
  let input = "{one: two, three: four}"

  input
  |> yaml.parse_ast()
  |> snap(input, "simple_flow_mapping_test")
}

pub fn whitespace_and_trailing_comma_flow_mapping_test() {
  let input = "{ one : two , three: four , }"

  input
  |> yaml.parse_ast()
  |> snap(input, "whitespace_and_trailing_comma_flow_mapping_test")
}

pub fn omitted_key_and_value_flow_mapping_test() {
  let input = "{omitted value:, : omitted key, solo}"

  input
  |> yaml.parse_ast()
  |> snap(input, "omitted_key_and_value_flow_mapping_test")
}

pub fn explicit_entries_flow_mapping_test() {
  let input = "{? explicit: entry, implicit: entry, ?}"

  input
  |> yaml.parse_ast()
  |> snap(input, "explicit_entries_flow_mapping_test")
}

pub fn adjacent_values_flow_mapping_test() {
  let input = "{adjacent :value, readable: value, empty:}"

  input
  |> yaml.parse_ast()
  |> snap(input, "adjacent_values_flow_mapping_test")
}

pub fn quoted_adjacent_values_flow_mapping_test() {
  let input = "{\"adjacent\":value, \"readable\": value, \"empty\":}"

  input
  |> yaml.parse_ast()
  |> snap(input, "quoted_adjacent_values_flow_mapping_test")
}

pub fn url_plain_key_flow_mapping_test() {
  let input = "{https://foo.com, other: value}"

  input
  |> yaml.parse_ast()
  |> snap(input, "url_plain_key_flow_mapping_test")
}

pub fn nested_collections_flow_mapping_test() {
  let input = "{seq: [one, two], map: {inner: value}}"

  input
  |> yaml.parse_ast()
  |> snap(input, "nested_collections_flow_mapping_test")
}

pub fn compact_mapping_in_sequence_test() {
  let input = "[foo: bar, {JSON: like}:adjacent]"

  input
  |> yaml.parse_ast()
  |> snap(input, "compact_mapping_in_sequence_test")
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
