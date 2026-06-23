import gleam/result
import yaml_ast.{Bool, Float, Int, Mapping, Nan, NegInf, Null, Sequence, String}
import yaml_helpers as helpers

pub fn example_2_1_sequence_of_scalars_test() {
  let input = "- Mark McGwire\n- Sammy Sosa\n- Ken Griffey"

  assert helpers.parse_ast(input)
    == Sequence([
      String("Mark McGwire"),
      String("Sammy Sosa"),
      String("Ken Griffey"),
    ])
    |> Ok
}

pub fn example_2_2_mapping_scalars_to_scalars_test() {
  let input = "hr:  65\navg: 0.278\nrbi: 147"

  assert helpers.parse_ast(input)
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

  assert helpers.parse_ast(input)
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

  assert helpers.parse_ast(input)
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

pub fn example_2_5_sequence_of_sequences_test() {
  let input =
    "- [name        , hr, avg  ]\n- [Mark McGwire, 65, 0.278]\n- [Sammy Sosa  , 63, 0.288]"

  assert helpers.parse_ast(input)
    == Sequence([
      Sequence([String("name"), String("hr"), String("avg")]),
      Sequence([String("Mark McGwire"), Int(65), Float(0.278)]),
      Sequence([String("Sammy Sosa"), Int(63), Float(0.288)]),
    ])
    |> Ok
}

pub fn example_2_6_mapping_of_mappings_test() {
  let input =
    "Mark McGwire: {hr: 65, avg: 0.278}\nSammy Sosa: {\n    hr: 63,\n    avg: 0.288,\n }"

  assert helpers.parse_ast(input)
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

pub fn example_2_7_two_documents_in_a_stream_test() {
  let input =
    "# Ranking of 1998 home runs\n---\n- Mark McGwire\n- Sammy Sosa\n- Ken Griffey\n\n# Team ranking\n---\n- Chicago Cubs\n- St Louis Cardinals"

  assert helpers.parse_ast_stream(input)
    == [
      Sequence([
        String("Mark McGwire"),
        String("Sammy Sosa"),
        String("Ken Griffey"),
      ]),
      Sequence([String("Chicago Cubs"), String("St Louis Cardinals")]),
    ]
    |> Ok
}

pub fn example_2_8_play_by_play_feed_test() {
  let input =
    "---\ntime: 20:03:20\nplayer: Sammy Sosa\naction: strike (miss)\n...\n---\ntime: 20:03:47\nplayer: Sammy Sosa\naction: grand slam\n..."

  assert helpers.parse_ast_stream(input)
    == [
      Mapping([
        #(String("time"), String("20:03:20")),
        #(String("player"), String("Sammy Sosa")),
        #(String("action"), String("strike (miss)")),
      ]),
      Mapping([
        #(String("time"), String("20:03:47")),
        #(String("player"), String("Sammy Sosa")),
        #(String("action"), String("grand slam")),
      ]),
    ]
    |> Ok
}

pub fn example_2_9_single_document_with_two_comments_test() {
  let input =
    "---\nhr: # 1998 hr ranking\n  - Mark McGwire\n  - Sammy Sosa\nrbi:\n  # 1998 rbi ranking\n  - Sammy Sosa\n  - Ken Griffey"

  assert helpers.parse_ast(input)
    == Mapping([
      #(String("hr"), Sequence([String("Mark McGwire"), String("Sammy Sosa")])),
      #(String("rbi"), Sequence([String("Sammy Sosa"), String("Ken Griffey")])),
    ])
    |> Ok
}

pub fn example_2_11_mapping_between_sequences_test() {
  let input =
    "? - Detroit Tigers\n  - Chicago cubs\n: - 2001-07-23\n\n? [ New York Yankees,\n    Atlanta Braves ]\n: [ 2001-07-02, 2001-08-12,\n    2001-08-14 ]"

  assert helpers.parse_ast(input)
    == Mapping([
      #(
        Sequence([String("Detroit Tigers"), String("Chicago cubs")]),
        Sequence([String("2001-07-23")]),
      ),
      #(
        Sequence([String("New York Yankees"), String("Atlanta Braves")]),
        Sequence([
          String("2001-07-02"),
          String("2001-08-12"),
          String("2001-08-14"),
        ]),
      ),
    ])
    |> Ok
}

pub fn example_2_12_compact_nested_mapping_test() {
  let input =
    "# Products purchased\n- item    : Super Hoop\n  quantity: 1\n- item    : Basketball\n  quantity: 4\n- item    : Big Shoes\n  quantity: 1"

  assert helpers.parse_ast(input)
    == Sequence([
      Mapping([
        #(String("item"), String("Super Hoop")),
        #(String("quantity"), Int(1)),
      ]),
      Mapping([
        #(String("item"), String("Basketball")),
        #(String("quantity"), Int(4)),
      ]),
      Mapping([
        #(String("item"), String("Big Shoes")),
        #(String("quantity"), Int(1)),
      ]),
    ])
    |> Ok
}

pub fn example_2_13_in_literals_newlines_are_preserved_test() {
  let input = "--- |\n  \\//||\\/||\n  // ||  ||__"

  assert helpers.parse_ast(input)
    == String("\\//||\\/||\n// ||  ||__\n")
    |> Ok
}

pub fn example_2_14_in_folded_scalars_newlines_become_spaces_test() {
  let input =
    "--- >\n  Mark McGwire's\n  year was crippled\n  by a knee injury."

  assert helpers.parse_ast(input)
    == String("Mark McGwire's year was crippled by a knee injury.\n")
    |> Ok
}

pub fn example_2_16_block_scalars_test() {
  let input =
    "name: Mark McGwire\naccomplishment: >\n  Mark set a major league\n  home run record in 1998.\nstats: |\n  65 Home Runs\n  0.278 Batting Average"

  assert helpers.parse_ast(input)
    == Mapping([
      #(String("name"), String("Mark McGwire")),
      #(
        String("accomplishment"),
        String("Mark set a major league home run record in 1998.\n"),
      ),
      #(String("stats"), String("65 Home Runs\n0.278 Batting Average\n")),
    ])
    |> Ok
}

pub fn example_2_17_quoted_scalars_test() {
  let input =
    "unicode: \"Sosa did fine.\\u263A\"\ncontrol: \"\\b1998\\t1999\\t2000\\n\"\nhex esc: \"\\x0d\\x0a is \\r\\n\"\n\nsingle: '\"Howdy!\" he cried.'\nquoted: ' # Not a ''comment''.'\ntie-fighter: '|\\-*-/|'"

  assert helpers.parse_ast(input)
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

  assert helpers.parse_ast(input)
    == Mapping([
      #(String("plain"), String("This unquoted scalar spans many lines.")),
      #(String("quoted"), String("So does this quoted scalar.\n")),
    ])
    |> Ok
}

pub fn example_2_19_integers_test() {
  let input = "canonical: 12345\ndecimal: +12345\noctal: 0o14\nhexadecimal: 0xC"

  assert helpers.parse_ast(input)
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

  assert helpers.parse_ast(input)
    == Mapping([
      #(String("canonical"), Float(1230.15)),
      #(String("exponential"), Float(1230.15)),
      #(String("fixed"), Float(1230.15)),
      #(String("negative infinity"), NegInf),
      #(String("not a number"), Nan),
    ])
    |> Ok
}

pub fn exponent_only_floating_point_scalars_test() {
  let input = "positive: 1e3\nsigned: +1e3\nnegative: -1E3"

  assert helpers.parse_ast(input)
    == Mapping([
      #(String("positive"), Float(1000.0)),
      #(String("signed"), Float(1000.0)),
      #(String("negative"), Float(-1000.0)),
    ])
    |> Ok
}

pub fn example_2_21_miscellaneous_test() {
  let input = "null:\nbooleans: [ true, false ]\nstring: '012345'"

  assert helpers.parse_ast(input)
    == Mapping([
      #(Null, Null),
      #(String("booleans"), Sequence([Bool(True), Bool(False)])),
      #(String("string"), String("012345")),
    ])
    |> Ok
}

pub fn example_5_4_flow_collection_indicators_test() {
  let input = "sequence: [ one, two, ]\nmapping: { sky: blue, sea: green }"

  assert helpers.parse_ast(input)
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

  assert helpers.parse_ast(input)
    == Sequence([
      String("Fun with \\"),
      String("\" \u{07} \u{08} \u{1B} \u{0C}"),
      String("\n \r \t \u{0B} \u{00}"),
      String("  \u{A0} \u{85} \u{2028} \u{2029} A A A"),
    ])
    |> Ok
}

pub fn example_5_14_invalid_escaped_characters_test() {
  assert helpers.parse_ast("\"\\c\"") |> result.is_error()
  assert helpers.parse_ast("\"\\x q-\"") |> result.is_error()
}

pub fn example_6_4_line_prefixes_test() {
  let input = "{ plain: text\n  \tlines, quoted: \"text\n  \tlines\" }"

  assert helpers.parse_ast(input)
    == Mapping([
      #(String("plain"), String("text lines")),
      #(String("quoted"), String("text lines")),
    ])
    |> Ok
}

pub fn example_6_5_empty_lines_test() {
  let input = "Folding: \"Empty line\n   \t\n  as a line feed\""

  assert helpers.parse_ast(input)
    == Mapping([#(String("Folding"), String("Empty line\nas a line feed"))])
    |> Ok
}

pub fn example_6_8_flow_folding_test() {
  let input = "\"  foo \n \n  \t bar\n\n  baz\n \""

  assert helpers.parse_ast(input)
    == String(" foo\nbar\nbaz ")
    |> Ok
}

pub fn example_7_4_double_quoted_implicit_keys_test() {
  let input = "{ \"implicit block key\": [ { \"implicit flow key\": value } ] }"

  assert helpers.parse_ast(input)
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

pub fn example_7_5_double_quoted_line_breaks_test() {
  let input =
    "\"folded \nto a space,\t\n \nto a line feed, or \t\\\n \\ \tnon-content\""

  assert helpers.parse_ast(input)
    == String("folded to a space,\nto a line feed, or \t \tnon-content")
    |> Ok
}

pub fn example_7_6_double_quoted_lines_test() {
  let input = "\" 1st non-empty\n\n 2nd non-empty \n\t3rd non-empty \""

  assert helpers.parse_ast(input)
    == String(" 1st non-empty\n2nd non-empty 3rd non-empty ")
    |> Ok
}

pub fn example_7_7_single_quoted_characters_test() {
  let input = "'here''s to \"quotes\"'"

  assert helpers.parse_ast(input)
    == String("here's to \"quotes\"")
    |> Ok
}

pub fn example_7_8_single_quoted_implicit_keys_test() {
  let input = "{ 'implicit block key': [ { 'implicit flow key': value } ] }"

  assert helpers.parse_ast(input)
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

  assert helpers.parse_ast(input)
    == String(" 1st non-empty\n2nd non-empty 3rd non-empty ")
    |> Ok
}

pub fn example_7_10_plain_characters_test() {
  let input =
    "# Outside flow collection:\n- ::vector\n- \": - ()\"\n- Up, up, and away!\n- -123\n- http://example.com/foo#bar\n# Inside flow collection:\n- [ ::vector,\n  \": - ()\",\n  \"Up, up, and away!\",\n  -123,\n  http://example.com/foo#bar ]"

  assert helpers.parse_ast(input)
    == Sequence([
      String("::vector"),
      String(": - ()"),
      String("Up, up, and away!"),
      Int(-123),
      String("http://example.com/foo#bar"),
      Sequence([
        String("::vector"),
        String(": - ()"),
        String("Up, up, and away!"),
        Int(-123),
        String("http://example.com/foo#bar"),
      ]),
    ])
    |> Ok
}

pub fn example_7_11_plain_implicit_keys_test() {
  let input = "{ implicit block key: [ { implicit flow key: value } ] }"

  assert helpers.parse_ast(input)
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

  assert helpers.parse_ast(input)
    == Sequence([String("1st non-empty\n2nd non-empty 3rd non-empty")])
    |> Ok
}

pub fn example_7_13_flow_sequence_test() {
  let input = "- [ one, two, ]\n- [three ,four]"

  assert helpers.parse_ast(input)
    == Sequence([
      Sequence([String("one"), String("two")]),
      Sequence([String("three"), String("four")]),
    ])
    |> Ok
}

pub fn example_7_14_flow_sequence_entries_test() {
  let input =
    "[\n\"double\n quoted\", 'single\n           quoted',\nplain\n text, [ nested ],\nsingle: pair,\n]"

  assert helpers.parse_ast(input)
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

  assert helpers.parse_ast(input)
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

  assert helpers.parse_ast(input)
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

  assert helpers.parse_ast(input)
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

  assert helpers.parse_ast(input)
    == Mapping([
      #(String("adjacent"), String("value")),
      #(String("readable"), String("value")),
      #(String("empty"), Null),
    ])
    |> Ok
}

pub fn example_7_19_single_pair_flow_mappings_test() {
  let input = "[foo: bar]"

  assert helpers.parse_ast(input)
    == Sequence([Mapping([#(String("foo"), String("bar"))])])
    |> Ok
}

pub fn example_7_20_single_pair_explicit_entry_test() {
  let input = "[? foo\n bar : baz]"

  assert helpers.parse_ast(input)
    == Sequence([Mapping([#(String("foo bar"), String("baz"))])])
    |> Ok
}

pub fn example_7_21_single_pair_implicit_entries_test() {
  let input =
    "- [ YAML : separate ]\n- [ : empty key entry ]\n- [ {JSON: like}:adjacent ]"

  assert helpers.parse_ast(input)
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

pub fn example_7_23_flow_content_test() {
  let input = "- [ a, b ]\n- { a: b }\n- \"a\"\n- 'b'\n- c"

  assert helpers.parse_ast(input)
    == Sequence([
      Sequence([String("a"), String("b")]),
      Mapping([#(String("a"), String("b"))]),
      String("a"),
      String("b"),
      String("c"),
    ])
    |> Ok
}

pub fn example_8_6_empty_scalar_chomping_test() {
  let input = "strip: >-\n\nclip: >\n\nkeep: |+\n\n"

  assert helpers.parse_ast(input)
    == Mapping([
      #(String("strip"), String("")),
      #(String("clip"), String("")),
      #(String("keep"), String("\n")),
    ])
    |> Ok
}

pub fn example_8_7_literal_scalar_test() {
  let input = "|\n literal\n \ttext\n"

  assert helpers.parse_ast(input)
    == String("literal\n\ttext\n")
    |> Ok
}

pub fn example_8_9_folded_scalar_test() {
  let input = ">\n folded\n text\n"

  assert helpers.parse_ast(input)
    == String("folded text\n")
    |> Ok
}

pub fn example_8_14_block_sequence_test() {
  let input = "block sequence:\n  - one\n  - two : three"

  assert helpers.parse_ast(input)
    == Mapping([
      #(
        String("block sequence"),
        Sequence([String("one"), Mapping([#(String("two"), String("three"))])]),
      ),
    ])
    |> Ok
}

pub fn example_8_15_block_sequence_entry_types_test() {
  let input =
    "- # Empty\n- |\n block node\n- - one # Compact\n  - two # sequence\n- one: two # Compact mapping"

  assert helpers.parse_ast(input)
    == Sequence([
      Null,
      String("block node\n"),
      Sequence([String("one"), String("two")]),
      Mapping([#(String("one"), String("two"))]),
    ])
    |> Ok
}

pub fn example_8_16_block_mappings_test() {
  let input = "block mapping:\n key: value"

  assert helpers.parse_ast(input)
    == Mapping([
      #(String("block mapping"), Mapping([#(String("key"), String("value"))])),
    ])
    |> Ok
}

pub fn example_8_17_explicit_block_mapping_entries_test() {
  let input =
    "? explicit key # Empty value\n? |\n  block key\n: - one # Explicit compact\n  - two # block value"

  assert helpers.parse_ast(input)
    == Mapping([
      #(String("explicit key"), Null),
      #(String("block key\n"), Sequence([String("one"), String("two")])),
    ])
    |> Ok
}

pub fn example_8_18_implicit_block_mapping_entries_test() {
  let input =
    "plain key: in-line value\n: # Both empty\n\"quoted key\":\n- entry"

  assert helpers.parse_ast(input)
    == Mapping([
      #(String("plain key"), String("in-line value")),
      #(Null, Null),
      #(String("quoted key"), Sequence([String("entry")])),
    ])
    |> Ok
}

pub fn example_8_19_compact_block_mappings_test() {
  let input = "- sun: yellow\n- ? earth: blue\n  : moon: white"

  assert helpers.parse_ast(input)
    == Sequence([
      Mapping([#(String("sun"), String("yellow"))]),
      Mapping([
        #(
          Mapping([#(String("earth"), String("blue"))]),
          Mapping([#(String("moon"), String("white"))]),
        ),
      ]),
    ])
    |> Ok
}
