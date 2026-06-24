import gleam/dynamic/decode
import gleam/list
import gleam/option
import gleam/result
import yaml_helpers as helpers
import yum/yaml
import yum/yaml/builder
import yum/yaml/diagnostic
import yum/yaml/node

pub fn node_exposes_kind_and_accessors_test() {
  let assert Ok(document) = helpers.parse_node("name: \"yum\"\n")
  let assert node.Mapping(entries) = node.kind(document)
  let assert [#(key, value)] = entries

  assert node.as_string(key) == Ok("name")
  assert node.as_string(value) == Ok("yum")
  assert node.style(document) == node.BlockMapping
  assert node.style(key) == node.PlainScalar
  assert node.style(value) == node.DoubleQuotedScalar
  assert node.span(document)
    == node.Span(start: node.Position(1, 1), end: node.Position(1, 12))
}

pub fn get_retrieves_nested_mapping_values_test() {
  let assert Ok(document) =
    helpers.parse_node("job:\n  script: [gleam, test]\n")
  let assert option.Some(script) =
    node.get(document, [
      node.Key("job"),
      node.Key("script"),
    ])
  let assert option.Some(command) = node.get(script, [node.Index(0)])

  assert node.as_string(command) == Ok("gleam")
}

pub fn get_keys_and_values_return_mapping_parts_test() {
  let assert Ok(document) = helpers.parse_node("name: yum\nlanguage: gleam\n")
  let assert Ok(keys) = node.get_keys(document)
  let assert Ok(values) = node.get_values(document)

  assert list.map(keys, node.as_string) == [Ok("name"), Ok("language")]
  assert list.map(values, node.as_string) == [Ok("yum"), Ok("gleam")]
}

pub fn node_tracks_flow_collection_style_and_span_test() {
  let assert Ok(document) = helpers.parse_node("commands: [gleam, test]\n")
  let assert option.Some(commands) = node.get(document, [node.Key("commands")])

  assert node.style(commands) == node.FlowSequence
  assert node.span(commands)
    == node.Span(start: node.Position(1, 11), end: node.Position(1, 24))
}

pub fn node_tracks_block_scalar_style_and_span_test() {
  let assert Ok(document) = helpers.parse_node("script: |\n  gleam test\n")
  let assert option.Some(script) = node.get(document, [node.Key("script")])

  assert node.style(script) == node.LiteralBlockScalar
  assert node.span(script)
    == node.Span(start: node.Position(1, 9), end: node.Position(2, 13))
}

pub fn decode_uses_dynamic_decoders_test() {
  let decoder = {
    use name <- decode.field("name", decode.string)
    use count <- decode.field("count", decode.int)
    decode.success(#(name, count))
  }

  assert yaml.decode("name: yum\ncount: 1", using: decoder) == Ok(#("yum", 1))
}

pub fn builder_and_emitter_round_trip_test() {
  let document =
    builder.mapping([
      #(builder.string("name"), builder.string("yum")),
      #(
        builder.string("commands"),
        builder.sequence([
          builder.string("gleam"),
          builder.string("test"),
        ]),
      ),
    ])

  let rendered =
    document
    |> yaml.from_node()
    |> yaml.to_string()

  assert rendered == "name: yum\ncommands:\n  - gleam\n  - test"
}

pub fn to_string_validates_emitted_yaml_test() {
  let document =
    builder.mapping([
      #(builder.string("name"), builder.string("yum")),
    ])

  let rendered =
    document
    |> yaml.from_node()
    |> yaml.to_string()

  assert helpers.parse_node(rendered) |> result.is_ok()
}

pub fn get_index_rejects_negative_indexes_test() {
  let document =
    builder.sequence([
      builder.string("first"),
    ])

  assert node.get_index(document, -1) == option.None
}

pub fn as_accessors_return_values_test() {
  let assert Ok(document) =
    helpers.parse_node(
      "name: yum\ncount: 1\nactive: true\nratio: 1.5\nempty: null\n",
    )
  let assert option.Some(name) = node.get(document, [node.Key("name")])
  let assert option.Some(count) = node.get(document, [node.Key("count")])
  let assert option.Some(active) = node.get(document, [node.Key("active")])
  let assert option.Some(ratio) = node.get(document, [node.Key("ratio")])
  let assert option.Some(empty) = node.get(document, [node.Key("empty")])

  assert node.as_mapping(document) |> result.is_ok()
  assert node.as_string(name) == Ok("yum")
  assert node.as_int(count) == Ok(1)
  assert node.as_bool(active) == Ok(True)
  assert node.as_float(ratio) == Ok(1.5)
  assert node.as_null(empty) == Ok(Nil)
}

pub fn as_accessors_return_typed_errors_test() {
  let assert Ok(document) = helpers.parse_node("count: 1\n")
  let assert option.Some(count) = node.get(document, [node.Key("count")])

  assert node.kind_name(count) == node.IntKind
  assert node.as_string(count)
    == Error(node.ExpectedKind(
      expected: node.StringKind,
      found: node.IntKind,
      span: node.Span(start: node.Position(1, 8), end: node.Position(1, 9)),
    ))
}

pub fn resolved_yaml_warns_for_duplicate_keys_test() {
  let assert Ok(helpers.Parsed(value: document, diagnostics: [warning])) =
    helpers.parse_node_with_diagnostics("name: one\nname: two\n")

  assert node.get(document, [node.Key("name")]) |> option.is_some()
  assert warning
    == diagnostic.DuplicateMappingKey(
      key: "name",
      duplicate: node.Span(start: node.Position(2, 1), end: node.Position(2, 6)),
      original: node.Span(start: node.Position(1, 1), end: node.Position(1, 6)),
    )
  assert diagnostic.severity(warning) == diagnostic.Warning
  assert diagnostic.message(warning) == "Duplicate mapping key `name`"
  assert diagnostic.related(warning)
    == [
      diagnostic.FirstMappingKey(span: node.Span(
        start: node.Position(1, 1),
        end: node.Position(1, 6),
      )),
    ]
}

pub fn diagnostics_collects_nested_duplicate_keys_test() {
  let assert Ok(helpers.Parsed(diagnostics: [warning], ..)) =
    helpers.parse_node_with_diagnostics("job:\n  script: one\n  script: two\n")

  assert warning
    == diagnostic.DuplicateMappingKey(
      key: "script",
      duplicate: node.Span(
        start: node.Position(3, 3),
        end: node.Position(3, 10),
      ),
      original: node.Span(start: node.Position(2, 3), end: node.Position(2, 10)),
    )
}
