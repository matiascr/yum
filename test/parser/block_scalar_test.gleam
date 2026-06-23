import birdie
import gleam/result
import gleam/string
import yaml_helpers as helpers
import yaml_render

const test_file_prefix = "parser:block_scalar:"

pub fn literal_clip_block_scalar_test() {
  let input = "|\n  line one\n  line two\n"

  input
  |> helpers.parse_ast()
  |> snap(input, "literal_clip_block_scalar_test")
}

pub fn literal_strip_block_scalar_test() {
  let input = "|-\n  line one\n  line two\n"

  input
  |> helpers.parse_ast()
  |> snap(input, "literal_strip_block_scalar_test")
}

pub fn literal_keep_block_scalar_test() {
  let input = "|+\n  line one\n  line two\n\n"

  input
  |> helpers.parse_ast()
  |> snap(input, "literal_keep_block_scalar_test")
}

pub fn folded_clip_block_scalar_test() {
  let input = ">\n  line one\n  line two\n\n  line four\n"

  input
  |> helpers.parse_ast()
  |> snap(input, "folded_clip_block_scalar_test")
}

pub fn nested_mapping_block_scalar_test() {
  let input = "outer:\n  literal: |\n    line one\n    line two\n  next: value"

  input
  |> helpers.parse_ast()
  |> snap(input, "nested_mapping_block_scalar_test")
}

pub fn sequence_block_scalar_test() {
  let input = "- |\n  first\n  second\n- >-\n  third\n  fourth"

  input
  |> helpers.parse_ast()
  |> snap(input, "sequence_block_scalar_test")
}

pub fn preserves_extra_indentation_block_scalar_test() {
  let input = "|\n  line one\n    indented\n  line three\n"

  input
  |> helpers.parse_ast()
  |> snap(input, "preserves_extra_indentation_block_scalar_test")
}

fn snap(parsed: _, input: String, title: String) {
  assert result.is_ok({
    use yaml <- result.try(parsed)
    let result = yaml_render.ast(yaml)

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
