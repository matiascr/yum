import yaml_ast as ast
import yaml_helpers as helpers
import yum/yaml
import yum/yaml/builder.{bool, int, mapping, null, sequence, string}

pub fn emitter_quotes_strings_that_would_parse_as_other_scalars_test() {
  let document =
    sequence([
      string("123"),
      string("0o10"),
      string("0x10"),
      string("1.5"),
      string(".nan"),
      string(".inf"),
      string("-.inf"),
      string("true"),
      string("null"),
      string("~"),
    ])

  let rendered =
    document
    |> yaml.from_node()
    |> yaml.to_string()

  assert rendered
    == "- \"123\"\n- \"0o10\"\n- \"0x10\"\n- \"1.5\"\n- \".nan\"\n- \".inf\"\n- \"-.inf\"\n- \"true\"\n- \"null\"\n- \"~\""
  assert helpers.parse_ast(rendered)
    == ast.Sequence([
      ast.String("123"),
      ast.String("0o10"),
      ast.String("0x10"),
      ast.String("1.5"),
      ast.String(".nan"),
      ast.String(".inf"),
      ast.String("-.inf"),
      ast.String("true"),
      ast.String("null"),
      ast.String("~"),
    ])
    |> Ok
}

pub fn emitter_quotes_strings_with_mapping_indicators_test() {
  let document =
    mapping([
      #(string("colon"), string("a: b")),
      #(string("hash"), string("a # b")),
      #(string("key:with:colon"), string("value")),
    ])

  assert document
    |> yaml.from_node()
    |> yaml.to_string()
    == "colon: \"a: b\"\nhash: \"a # b\"\n\"key:with:colon\": value"
}

pub fn emitter_quotes_empty_and_whitespace_sensitive_strings_test() {
  let document =
    sequence([
      string(""),
      string(" leading"),
      string("trailing "),
      string(" "),
    ])

  assert document
    |> yaml.from_node()
    |> yaml.to_string()
    == "- \"\"\n- \" leading\"\n- \"trailing \"\n- \" \""
}

pub fn emitter_handles_nested_block_collections_test() {
  let document =
    mapping([
      #(
        string("jobs"),
        sequence([
          mapping([
            #(string("name"), string("test")),
            #(
              string("steps"),
              sequence([
                string("gleam test"),
                string("gleam format"),
              ]),
            ),
          ]),
        ]),
      ),
    ])

  assert document
    |> yaml.from_node()
    |> yaml.to_string()
    == "jobs:\n  - name: test\n    steps:\n      - gleam test\n      - gleam format"
}

pub fn emitter_emits_non_string_scalar_keys_test() {
  let document =
    mapping([
      #(int(1), string("one")),
      #(bool(True), string("yes")),
      #(null(), string("empty")),
    ])

  let rendered =
    document
    |> yaml.from_node()
    |> yaml.to_string()

  assert helpers.parse_ast(rendered)
    == ast.Mapping([
      #(ast.Int(1), ast.String("one")),
      #(ast.Bool(True), ast.String("yes")),
      #(ast.Null, ast.String("empty")),
    ])
    |> Ok
}
