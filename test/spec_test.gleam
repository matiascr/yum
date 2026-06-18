import gleam/result
import yaml.{Sequence, String}
import yum

pub fn example_2_18_multi_line_flow_scalars_test() {
  let input = "\"So does this\n  quoted scalar.\\n\""

  assert yum.parse(input)
    == String("So does this quoted scalar.\n")
    |> Ok
}

pub fn example_2_17_single_quoted_scalar_test() {
  let input = "'\"Howdy!\" he cried.'"

  assert yum.parse(input)
    == String("\"Howdy!\" he cried.")
    |> Ok
}

pub fn example_2_17_single_quoted_comment_text_test() {
  let input = "' # Not a ''comment''.'"

  assert yum.parse(input)
    == String(" # Not a 'comment'.")
    |> Ok
}

pub fn example_2_17_single_quoted_backslash_test() {
  let input = "'|\\-*-/|'"

  assert yum.parse(input)
    == String("|\\-*-/|")
    |> Ok
}

pub fn example_5_13_escaped_characters_test() {
  let input =
    "[\"Fun with \\\\\", \"\\\" \\a \\b \\e \\f\", \"\\n \\r \\t \\v \\0\", \"\\  \\_ \\N \\L \\P \\\n  \\x41 \\u0041 \\U00000041\"]"

  assert yum.parse(input)
    == Sequence([
      String("Fun with \\"),
      String("\" \u{07} \u{08} \u{1B} \u{0C}"),
      String("\n \r \t \u{0B} \u{00}"),
      String("  \u{A0} \u{85} \u{2028} \u{2029} A A A"),
    ])
    |> Ok
}

pub fn example_5_14_invalid_escaped_characters_test() {
  assert yum.parse("\"\\c\"") |> result.is_error()
  assert yum.parse("\"\\x q-\"") |> result.is_error()
}

pub fn example_6_4_line_prefixes_test() {
  let input = "\"text\n  \tlines\""

  assert yum.parse(input)
    == String("text lines")
    |> Ok
}

pub fn example_6_5_empty_lines_test() {
  let input = "\"Empty line\n   \t\nas a line feed\""

  assert yum.parse(input)
    == String("Empty line\nas a line feed")
    |> Ok
}

pub fn example_6_8_flow_folding_test() {
  let input = "\"  foo \n \n  \t bar\n\n  baz\n \""

  assert yum.parse(input)
    == String(" foo\nbar\nbaz ")
    |> Ok
}

pub fn example_7_5_double_quoted_line_breaks_test() {
  let input =
    "\"folded \nto a space,\t\n \nto a line feed, or \t\\\n \\ \tnon-content\""

  assert yum.parse(input)
    == String("folded to a space,\nto a line feed, or \t \tnon-content")
    |> Ok
}

pub fn example_7_6_double_quoted_lines_test() {
  let input = "\" 1st non-empty\n\n 2nd non-empty \n\t3rd non-empty \""

  assert yum.parse(input)
    == String(" 1st non-empty\n2nd non-empty 3rd non-empty ")
    |> Ok
}

pub fn example_7_7_single_quoted_characters_test() {
  let input = "'here''s to \"quotes\"'"

  assert yum.parse(input)
    == String("here's to \"quotes\"")
    |> Ok
}

pub fn example_7_9_single_quoted_lines_test() {
  let input = "' 1st non-empty\n\n 2nd non-empty \n\t3rd non-empty '"

  assert yum.parse(input)
    == String(" 1st non-empty\n2nd non-empty 3rd non-empty ")
    |> Ok
}

pub fn example_7_13_flow_sequence_test() {
  let input = "[[ one, two, ], [three ,four]]"

  assert yum.parse(input)
    == Sequence([
      Sequence([String("one"), String("two")]),
      Sequence([String("three"), String("four")]),
    ])
    |> Ok
}

pub fn example_7_14_flow_sequence_entries_test() {
  let input =
    "[\n\"double\n quoted\", 'single\n           quoted',\nplain\n text, [ nested ],\n]"

  assert yum.parse(input)
    == Sequence([
      String("double quoted"),
      String("single quoted"),
      String("plain text"),
      Sequence([String("nested")]),
    ])
    |> Ok
}
