import gleam/result
import yum/yaml
import yum/yaml/ast.{
  Bool, Float, Int, Mapping, Nan, NegInf, Null, Sequence, String,
}

pub fn example_2_1_sequence_of_scalars_test() {
  let input = "- Mark McGwire\n- Sammy Sosa\n- Ken Griffey"

  assert yaml.parse_ast(input)
    == Sequence([
      String("Mark McGwire"),
      String("Sammy Sosa"),
      String("Ken Griffey"),
    ])
    |> Ok
}

pub fn example_2_2_mapping_scalars_to_scalars_test() {
  let input = "hr:  65\navg: 0.278\nrbi: 147"

  assert yaml.parse_ast(input)
    == Mapping([
      #(String("hr"), Int(65)),
      #(String("avg"), Float(0.278)),
      #(String("rbi"), Int(147)),
    ])
    |> Ok
}

pub fn example_2_3_mapping_scalars_to_sequences_test() {
  let input =
    "american:\n- Boston Red Sox\n- Detroit Tigers\n- New York Yankees\nnational:\n- New York Mets\n- Chicago Cubs\n- Atlanta Braves"

  assert yaml.parse_ast(input)
    == Mapping([
      #(
        String("american"),
        Sequence([
          String("Boston Red Sox"),
          String("Detroit Tigers"),
          String("New York Yankees"),
        ]),
      ),
      #(
        String("national"),
        Sequence([
          String("New York Mets"),
          String("Chicago Cubs"),
          String("Atlanta Braves"),
        ]),
      ),
    ])
    |> Ok
}

pub fn example_2_4_sequence_of_mappings_test() {
  let input =
    "-\n  name: Mark McGwire\n  hr:   65\n  avg:  0.278\n-\n  name: Sammy Sosa\n  hr:   63\n  avg:  0.288"

  assert yaml.parse_ast(input)
    == Sequence([
      Mapping([
        #(String("name"), String("Mark McGwire")),
        #(String("hr"), Int(65)),
        #(String("avg"), Float(0.278)),
      ]),
      Mapping([
        #(String("name"), String("Sammy Sosa")),
        #(String("hr"), Int(63)),
        #(String("avg"), Float(0.288)),
      ]),
    ])
    |> Ok
}

pub fn example_2_6_mapping_of_mappings_test() {
  let input =
    "Mark McGwire: {hr: 65, avg: 0.278}\nSammy Sosa: {\n    hr: 63,\n    avg: 0.288,\n }"

  assert yaml.parse_ast(input)
    == Mapping([
      #(
        String("Mark McGwire"),
        Mapping([
          #(String("hr"), Int(65)),
          #(String("avg"), Float(0.278)),
        ]),
      ),
      #(
        String("Sammy Sosa"),
        Mapping([
          #(String("hr"), Int(63)),
          #(String("avg"), Float(0.288)),
        ]),
      ),
    ])
    |> Ok
}

pub fn example_2_17_quoted_scalars_test() {
  let input =
    "unicode: \"Sosa did fine.\\u263A\"\ncontrol: \"\\b1998\\t1999\\t2000\\n\"\nhex esc: \"\\x0d\\x0a is \\r\\n\"\n\nsingle: '\"Howdy!\" he cried.'\nquoted: ' # Not a ''comment''.'\ntie-fighter: '|\\-*-/|'"

  assert yaml.parse_ast(input)
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

  assert yaml.parse_ast(input)
    == Mapping([
      #(String("plain"), String("This unquoted scalar spans many lines.")),
      #(String("quoted"), String("So does this quoted scalar.\n")),
    ])
    |> Ok
}

pub fn example_5_4_flow_collection_indicators_test() {
  let input = "sequence: [ one, two, ]\nmapping: { sky: blue, sea: green }"

  assert yaml.parse_ast(input)
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
    "- \"Fun with "
    <> "\\\\"
    <> "\"\n- \"\\\" \\a \\b \\e \\f\"\n- \"\\n \\r \\t \\v \\0\"\n- \"\\  \\_ \\N \\L \\P \\\n  \\x41 \\u0041 \\U00000041\""

  assert yaml.parse_ast(input)
    == Sequence([
      String("Fun with \\"),
      String("\" \u{07} \u{08} \u{1B} \u{0C}"),
      String("\n \r \t \u{0B} \u{00}"),
      String("  \u{A0} \u{85} \u{2028} \u{2029} A A A"),
    ])
    |> Ok
}

pub fn example_5_14_invalid_escaped_characters_test() {
  assert yaml.parse_ast("\"\\c\"") |> result.is_error()
  assert yaml.parse_ast("\"\\x q-\"") |> result.is_error()
}

pub fn example_6_4_line_prefixes_test() {
  let input = "{ plain: text\n  \tlines, quoted: \"text\n  \tlines\" }"

  assert yaml.parse_ast(input)
    == Mapping([
      #(String("plain"), String("text lines")),
      #(String("quoted"), String("text lines")),
    ])
    |> Ok
}

pub fn example_6_5_empty_lines_test() {
  let input = "Folding: \"Empty line\n   \t\n  as a line feed\""

  assert yaml.parse_ast(input)
    == Mapping([#(String("Folding"), String("Empty line\nas a line feed"))])
    |> Ok
}

pub fn example_2_19_integers_test() {
  let input = "canonical: 12345\ndecimal: +12345\noctal: 0o14\nhexadecimal: 0xC"

  assert yaml.parse_ast(input)
    == Mapping([
      #(String("canonical"), Int(12_345)),
      #(String("decimal"), Int(12_345)),
      #(String("octal"), Int(12)),
      #(String("hexadecimal"), Int(12)),
    ])
    |> Ok
}

pub fn example_2_20_floating_point_test() {
  let input =
    "canonical: 1.23015e+3\nexponential: 12.3015e+02\nfixed: 1230.15\nnegative infinity: -.inf\nnot a number: .nan"

  assert yaml.parse_ast(input)
    == Mapping([
      #(String("canonical"), Float(1230.15)),
      #(String("exponential"), Float(1230.15)),
      #(String("fixed"), Float(1230.15)),
      #(String("negative infinity"), NegInf),
      #(String("not a number"), Nan),
    ])
    |> Ok
}

pub fn example_2_21_miscellaneous_test() {
  let input = "null:\nbooleans: [ true, false ]\nstring: '012345'"

  assert yaml.parse_ast(input)
    == Mapping([
      #(Null, Null),
      #(String("booleans"), Sequence([Bool(True), Bool(False)])),
      #(String("string"), String("012345")),
    ])
    |> Ok
}

pub fn example_6_8_flow_folding_test() {
  let input = "\"  foo \n \n  \t bar\n\n  baz\n \""

  assert yaml.parse_ast(input)
    == String(" foo\nbar\nbaz ")
    |> Ok
}

pub fn example_7_5_double_quoted_line_breaks_test() {
  let input =
    "\"folded \nto a space,\t\n \nto a line feed, or \t\\\n \\ \tnon-content\""

  assert yaml.parse_ast(input)
    == String("folded to a space,\nto a line feed, or \t \tnon-content")
    |> Ok
}

pub fn example_7_6_double_quoted_lines_test() {
  let input = "\" 1st non-empty\n\n 2nd non-empty \n\t3rd non-empty \""

  assert yaml.parse_ast(input)
    == String(" 1st non-empty\n2nd non-empty 3rd non-empty ")
    |> Ok
}

pub fn example_7_4_double_quoted_implicit_keys_test() {
  let input = "{ \"implicit block key\": [ { \"implicit flow key\": value } ] }"

  assert yaml.parse_ast(input)
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

  assert yaml.parse_ast(input)
    == String("here's to \"quotes\"")
    |> Ok
}

pub fn example_7_8_single_quoted_implicit_keys_test() {
  let input = "{ 'implicit block key': [ { 'implicit flow key': value } ] }"

  assert yaml.parse_ast(input)
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

  assert yaml.parse_ast(input)
    == String(" 1st non-empty\n2nd non-empty 3rd non-empty ")
    |> Ok
}

pub fn example_7_11_plain_implicit_keys_test() {
  let input = "{ implicit block key: [ { implicit flow key: value } ] }"

  assert yaml.parse_ast(input)
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

  assert yaml.parse_ast(input)
    == Sequence([String("1st non-empty\n2nd non-empty 3rd non-empty")])
    |> Ok
}

pub fn example_7_13_flow_sequence_test() {
  let input = "- [ one, two, ]\n- [three ,four]"

  assert yaml.parse_ast(input)
    == Sequence([
      Sequence([String("one"), String("two")]),
      Sequence([String("three"), String("four")]),
    ])
    |> Ok
}

pub fn example_7_23_flow_content_test() {
  let input = "- [ a, b ]\n- { a: b }\n- \"a\"\n- 'b'\n- c"

  assert yaml.parse_ast(input)
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

  assert yaml.parse_ast(input)
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
  let input = "- { one : two , three: four , }\n- {five: six,seven : eight}"

  assert yaml.parse_ast(input)
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

  assert yaml.parse_ast(input)
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

  assert yaml.parse_ast(input)
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

  assert yaml.parse_ast(input)
    == Mapping([
      #(String("adjacent"), String("value")),
      #(String("readable"), String("value")),
      #(String("empty"), Null),
    ])
    |> Ok
}

pub fn example_7_19_single_pair_flow_mappings_test() {
  let input = "[foo: bar]"

  assert yaml.parse_ast(input)
    == Sequence([Mapping([#(String("foo"), String("bar"))])])
    |> Ok
}

pub fn example_7_20_single_pair_explicit_entry_test() {
  let input = "[? foo\n bar : baz]"

  assert yaml.parse_ast(input)
    == Sequence([Mapping([#(String("foo bar"), String("baz"))])])
    |> Ok
}

pub fn example_7_21_single_pair_implicit_entries_test() {
  let input =
    "- [ YAML : separate ]\n- [ : empty key entry ]\n- [ {JSON: like}:adjacent ]"

  assert yaml.parse_ast(input)
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
