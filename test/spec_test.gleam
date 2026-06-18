import gleam/result
import yaml
import yum

pub fn example_2_18_multi_line_flow_scalars_test() {
  let input = "\"So does this\n  quoted scalar.\\n\""

  assert yum.parse(input)
    == yaml.String("So does this quoted scalar.\n")
    |> Ok
}

pub fn example_2_17_single_quoted_scalar_test() {
  let input = "'\"Howdy!\" he cried.'"

  assert yum.parse(input)
    == yaml.String("\"Howdy!\" he cried.")
    |> Ok
}

pub fn example_2_17_single_quoted_comment_text_test() {
  let input = "' # Not a ''comment''.'"

  assert yum.parse(input)
    == yaml.String(" # Not a 'comment'.")
    |> Ok
}

pub fn example_2_17_single_quoted_backslash_test() {
  let input = "'|\\-*-/|'"

  assert yum.parse(input)
    == yaml.String("|\\-*-/|")
    |> Ok
}

pub fn example_5_13_escaped_backslash_characters_test() {
  let input = "\"Fun with \\\\\""

  assert yum.parse(input)
    == yaml.String("Fun with \\")
    |> Ok
}

pub fn example_5_13_escaped_control_characters_test() {
  let input = "\"\\\" \\a \\b \\e \\f\""

  assert yum.parse(input)
    == yaml.String("\" \u{07} \u{08} \u{1B} \u{0C}")
    |> Ok
}

pub fn example_5_13_escaped_line_characters_test() {
  let input = "\"\\n \\r \\t \\v \\0\""

  assert yum.parse(input)
    == yaml.String("\n \r \t \u{0B} \u{00}")
    |> Ok
}

pub fn example_5_13_escaped_unicode_characters_test() {
  let input = "\"\\  \\_ \\N \\L \\P \\\n  \\x41 \\u0041 \\U00000041\""

  assert yum.parse(input)
    == yaml.String("  \u{A0} \u{85} \u{2028} \u{2029} A A A")
    |> Ok
}

pub fn example_5_14_invalid_escaped_characters_test() {
  assert result.is_error(yum.parse("\"\\c\""))
  assert result.is_error(yum.parse("\"\\x q-\""))
}

pub fn example_6_4_line_prefixes_test() {
  let input = "\"text\n  \tlines\""

  assert yum.parse(input)
    == yaml.String("text lines")
    |> Ok
}

pub fn example_6_5_empty_lines_test() {
  let input = "\"Empty line\n   \t\nas a line feed\""

  assert yum.parse(input)
    == yaml.String("Empty line\nas a line feed")
    |> Ok
}

pub fn example_6_8_flow_folding_test() {
  let input = "\"  foo \n \n  \t bar\n\n  baz\n \""

  assert yum.parse(input)
    == yaml.String(" foo\nbar\nbaz ")
    |> Ok
}

pub fn example_7_5_double_quoted_line_breaks_test() {
  let input =
    "\"folded \nto a space,\t\n \nto a line feed, or \t\\\n \\ \tnon-content\""

  assert yum.parse(input)
    == yaml.String("folded to a space,\nto a line feed, or \t \tnon-content")
    |> Ok
}

pub fn example_7_6_double_quoted_lines_test() {
  let input = "\" 1st non-empty\n\n 2nd non-empty \n\t3rd non-empty \""

  assert yum.parse(input)
    == yaml.String(" 1st non-empty\n2nd non-empty 3rd non-empty ")
    |> Ok
}

pub fn example_7_7_single_quoted_characters_test() {
  let input = "'here''s to \"quotes\"'"

  assert yum.parse(input)
    == yaml.String("here's to \"quotes\"")
    |> Ok
}

pub fn example_7_9_single_quoted_lines_test() {
  let input = "' 1st non-empty\n\n 2nd non-empty \n\t3rd non-empty '"

  assert yum.parse(input)
    == yaml.String(" 1st non-empty\n2nd non-empty 3rd non-empty ")
    |> Ok
}
