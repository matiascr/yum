import birdie
import gleam/result
import gleam/string
import yaml_helpers as helpers

const test_file_prefix = "parser:flow_sequence:"

pub fn empty_flow_sequence_test() {
  let input = "[]"

  input
  |> helpers.parse_ast()
  |> snap(input, "empty_flow_sequence_test")
}

pub fn simple_flow_sequence_test() {
  let input = "[one, two, three]"

  input
  |> helpers.parse_ast()
  |> snap(input, "simple_flow_sequence_test")
}

pub fn trailing_comma_flow_sequence_test() {
  let input = "[one, two,]"

  input
  |> helpers.parse_ast()
  |> snap(input, "trailing_comma_flow_sequence_test")
}

pub fn adjacent_entries_flow_sequence_test() {
  let input = "[one,two,three]"

  input
  |> helpers.parse_ast()
  |> snap(input, "adjacent_entries_flow_sequence_test")
}

pub fn mixed_primitives_flow_sequence_test() {
  let input = "[null, true, false, 123, 1.5, .nan]"

  input
  |> helpers.parse_ast()
  |> snap(input, "mixed_primitives_flow_sequence_test")
}

pub fn quoted_entries_flow_sequence_test() {
  let input = "[\"double quoted\", 'single ''quoted''']"

  input
  |> helpers.parse_ast()
  |> snap(input, "quoted_entries_flow_sequence_test")
}

pub fn multiline_entries_flow_sequence_test() {
  let input = "[\"double\n quoted\", 'single\n quoted', plain\n text]"

  input
  |> helpers.parse_ast()
  |> snap(input, "multiline_entries_flow_sequence_test")
}

pub fn nested_flow_sequence_test() {
  let input = "[one, [two, three], four]"

  input
  |> helpers.parse_ast()
  |> snap(input, "nested_flow_sequence_test")
}

pub fn nested_empty_flow_sequence_test() {
  let input = "[[], [one], []]"

  input
  |> helpers.parse_ast()
  |> snap(input, "nested_empty_flow_sequence_test")
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
