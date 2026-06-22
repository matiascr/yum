import birdie
import gleam/result
import gleam/string
import yum/yaml

const test_file_prefix = "parser:block_sequence:"

pub fn simple_block_sequence_test() {
  let input = "- one\n- two\n- three"

  input
  |> yaml.parse_ast()
  |> snap(input, "simple_block_sequence_test")
}

pub fn trailing_line_break_block_sequence_test() {
  let input = "- one\n- two\n"

  input
  |> yaml.parse_ast()
  |> snap(input, "trailing_line_break_block_sequence_test")
}

pub fn blank_lines_block_sequence_test() {
  let input = "- one\n\n- two\n\n\n- three"

  input
  |> yaml.parse_ast()
  |> snap(input, "blank_lines_block_sequence_test")
}

pub fn empty_entries_block_sequence_test() {
  let input = "-\n- two\n-"

  input
  |> yaml.parse_ast()
  |> snap(input, "empty_entries_block_sequence_test")
}

pub fn nested_block_sequence_test() {
  let input = "-\n  - one\n  - two\n- three"

  input
  |> yaml.parse_ast()
  |> snap(input, "nested_block_sequence_test")
}

pub fn mixed_nodes_block_sequence_test() {
  let input =
    "- null\n- true\n- 123\n- [one, two]\n- {key: value}\n- \"double quoted\"\n- 'single quoted'"

  input
  |> yaml.parse_ast()
  |> snap(input, "mixed_nodes_block_sequence_test")
}

pub fn dash_inside_scalar_block_sequence_test() {
  let input = "- one-two\n- --not an entry marker"

  input
  |> yaml.parse_ast()
  |> snap(input, "dash_inside_scalar_block_sequence_test")
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
