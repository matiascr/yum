import gleam/result
import yum/yaml

pub fn unclosed_double_quoted_scalar_fails_test() {
  assert_fails("\"unterminated")
}

pub fn invalid_double_quoted_escape_fails_test() {
  assert_fails("\"bad \\q escape\"")
}

pub fn unclosed_single_quoted_scalar_fails_test() {
  assert_fails("'unterminated")
}

pub fn unclosed_flow_sequence_fails_test() {
  assert_fails("[one, two")
}

pub fn mismatched_flow_sequence_close_fails_test() {
  assert_fails("[one, two}")
}

pub fn nested_unclosed_flow_mapping_fails_test() {
  assert_fails("[one, {two: three]")
}

pub fn unclosed_flow_mapping_fails_test() {
  assert_fails("{one: two")
}

pub fn mismatched_flow_mapping_close_fails_test() {
  assert_fails("{one: two, three: four]")
}

pub fn unclosed_flow_sequence_explicit_block_key_fails_test() {
  assert_fails("? [one, two\n: value")
}

pub fn unclosed_flow_mapping_explicit_block_key_fails_test() {
  assert_fails("? {left: right\n: value")
}

pub fn block_sequence_unexpected_deeper_sibling_fails_test() {
  assert_fails("- one\n - two")
}

pub fn block_mapping_unexpected_intermediate_sibling_indent_fails_test() {
  assert_fails("key:\n  child: value\n sibling: value")
}

pub fn explicit_block_mapping_value_at_wrong_indent_fails_test() {
  assert_fails("?\n  left: one\n : mapping key")
}

pub fn top_level_block_scalar_unindented_content_fails_test() {
  assert_fails("|\nnot content")
}

pub fn mapping_block_scalar_unindented_content_fails_test() {
  assert_fails("key: |\nvalue")
}

fn assert_fails(input: String) {
  assert input |> yaml.parse_ast() |> result.is_error()
}
