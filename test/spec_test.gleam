import gleam/result
import yaml.{Mapping, Null, Sequence, String}
import yum

pub fn example_2_17_quoted_scalars_test() {
  let input =
    "{ unicode: \"Sosa did fine.\\u263A\", control: \"\\b1998\\t1999\\t2000\\n\", hex esc: \"\\x0d\\x0a is \\r\\n\", single: '\"Howdy!\" he cried.', quoted: ' # Not a ''comment''.', tie-fighter: '|\\-*-/|' }"

  assert yum.parse(input)
    == Mapping([
      #(String("unicode"), String("Sosa did fine.☺")),
      #(String("control"), String("\u{08}1998\t1999\t2000\n")),
      #(String("hex esc"), String("\r\n is \r\n")),
      #(String("single"), String("\"Howdy!\" he cried.")),
      #(String("quoted"), String(" # Not a 'comment'.")),
      #(String("tie-fighter"), String("|\\-*-/|")),
    ])
    |> Ok
}

pub fn example_2_18_multi_line_flow_scalars_test() {
  let input =
    "{ plain: This unquoted scalar\n  spans many lines., quoted: \"So does this\n  quoted scalar.\\n\" }"

  assert yum.parse(input)
    == Mapping([
      #(String("plain"), String("This unquoted scalar spans many lines.")),
      #(String("quoted"), String("So does this quoted scalar.\n")),
    ])
    |> Ok
}

pub fn example_5_4_flow_collection_indicators_test() {
  let input = "{ sequence: [ one, two, ], mapping: { sky: blue, sea: green } }"

  assert yum.parse(input)
    == Mapping([
      #(String("sequence"), Sequence([String("one"), String("two")])),
      #(
        String("mapping"),
        Mapping([
          #(String("sky"), String("blue")),
          #(String("sea"), String("green")),
        ]),
      ),
    ])
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
  let input = "{ plain: text\n  \tlines, quoted: \"text\n  \tlines\" }"

  assert yum.parse(input)
    == Mapping([
      #(String("plain"), String("text lines")),
      #(String("quoted"), String("text lines")),
    ])
    |> Ok
}

pub fn example_6_5_empty_lines_test() {
  let input = "{ Folding: \"Empty line\n   \t\n  as a line feed\" }"

  assert yum.parse(input)
    == Mapping([#(String("Folding"), String("Empty line\nas a line feed"))])
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

pub fn example_7_4_double_quoted_implicit_keys_test() {
  let input = "{ \"implicit block key\": [ { \"implicit flow key\": value } ] }"

  assert yum.parse(input)
    == Mapping([
      #(
        String("implicit block key"),
        Sequence([
          Mapping([#(String("implicit flow key"), String("value"))]),
        ]),
      ),
    ])
    |> Ok
}

pub fn example_7_7_single_quoted_characters_test() {
  let input = "'here''s to \"quotes\"'"

  assert yum.parse(input)
    == String("here's to \"quotes\"")
    |> Ok
}

pub fn example_7_8_single_quoted_implicit_keys_test() {
  let input = "{ 'implicit block key': [ { 'implicit flow key': value } ] }"

  assert yum.parse(input)
    == Mapping([
      #(
        String("implicit block key"),
        Sequence([
          Mapping([#(String("implicit flow key"), String("value"))]),
        ]),
      ),
    ])
    |> Ok
}

pub fn example_7_9_single_quoted_lines_test() {
  let input = "' 1st non-empty\n\n 2nd non-empty \n\t3rd non-empty '"

  assert yum.parse(input)
    == String(" 1st non-empty\n2nd non-empty 3rd non-empty ")
    |> Ok
}

pub fn example_7_11_plain_implicit_keys_test() {
  let input = "{ implicit block key: [ { implicit flow key: value } ] }"

  assert yum.parse(input)
    == Mapping([
      #(
        String("implicit block key"),
        Sequence([
          Mapping([#(String("implicit flow key"), String("value"))]),
        ]),
      ),
    ])
    |> Ok
}

pub fn example_7_12_plain_lines_test() {
  let input = "[1st non-empty\n\n 2nd non-empty \n\t3rd non-empty]"

  assert yum.parse(input)
    == Sequence([String("1st non-empty\n2nd non-empty 3rd non-empty")])
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

pub fn example_7_23_flow_content_test() {
  let input = "[ [ a, b ], { a: b }, \"a\", 'b', c ]"

  assert yum.parse(input)
    == Sequence([
      Sequence([String("a"), String("b")]),
      Mapping([#(String("a"), String("b"))]),
      String("a"),
      String("b"),
      String("c"),
    ])
    |> Ok
}

pub fn example_7_14_flow_sequence_entries_test() {
  let input =
    "[\n\"double\n quoted\", 'single\n           quoted',\nplain\n text, [ nested ],\nsingle: pair,\n]"

  assert yum.parse(input)
    == Sequence([
      String("double quoted"),
      String("single quoted"),
      String("plain text"),
      Sequence([String("nested")]),
      Mapping([#(String("single"), String("pair"))]),
    ])
    |> Ok
}

pub fn example_7_15_flow_mappings_test() {
  let input = "[{ one : two , three: four , }, {five: six,seven : eight}]"

  assert yum.parse(input)
    == Sequence([
      Mapping([
        #(String("one"), String("two")),
        #(String("three"), String("four")),
      ]),
      Mapping([
        #(String("five"), String("six")),
        #(String("seven"), String("eight")),
      ]),
    ])
    |> Ok
}

pub fn example_7_16_flow_mapping_entries_test() {
  let input = "{ ? explicit: entry, implicit: entry, ? }"

  assert yum.parse(input)
    == Mapping([
      #(String("explicit"), String("entry")),
      #(String("implicit"), String("entry")),
      #(Null, Null),
    ])
    |> Ok
}

pub fn example_7_17_flow_mapping_separate_values_test() {
  let input =
    "{ unquoted : \"separate\", https://foo.com, omitted value:, : omitted key }"

  assert yum.parse(input)
    == Mapping([
      #(String("unquoted"), String("separate")),
      #(String("https://foo.com"), Null),
      #(String("omitted value"), Null),
      #(Null, String("omitted key")),
    ])
    |> Ok
}

pub fn example_7_18_flow_mapping_adjacent_values_test() {
  let input = "{ \"adjacent\":value, \"readable\": value, \"empty\": }"

  assert yum.parse(input)
    == Mapping([
      #(String("adjacent"), String("value")),
      #(String("readable"), String("value")),
      #(String("empty"), Null),
    ])
    |> Ok
}

pub fn example_7_19_single_pair_flow_mappings_test() {
  let input = "[foo: bar]"

  assert yum.parse(input)
    == Sequence([Mapping([#(String("foo"), String("bar"))])])
    |> Ok
}

pub fn example_7_20_single_pair_explicit_entry_test() {
  let input = "[? foo\n bar : baz]"

  assert yum.parse(input)
    == Sequence([Mapping([#(String("foo bar"), String("baz"))])])
    |> Ok
}

pub fn example_7_21_single_pair_implicit_entries_test() {
  let input =
    "[[ YAML : separate ], [ : empty key entry ], [ {JSON: like}:adjacent ]]"

  assert yum.parse(input)
    == Sequence([
      Sequence([Mapping([#(String("YAML"), String("separate"))])]),
      Sequence([Mapping([#(Null, String("empty key entry"))])]),
      Sequence([
        Mapping([
          #(Mapping([#(String("JSON"), String("like"))]), String("adjacent")),
        ]),
      ]),
    ])
    |> Ok
}
