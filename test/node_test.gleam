import gleam/dynamic/decode
import gleam/option
import gleam/result
import yum/yaml
import yum/yaml/builder
import yum/yaml/diagnostic
import yum/yaml/node

pub fn parse_node_exposes_kind_and_accessors_test() {
  let assert Ok(document) = yaml.parse_node("name: \"yum\"\n")
  let assert node.Mapping(entries) = node.kind(document)
  let assert [#(key, value)] = entries

  assert node.as_string(key) == option.Some("name")
  assert node.as_string(value) == option.Some("yum")
  assert node.style(document) == node.BlockMapping
  assert node.style(key) == node.PlainScalar
  assert node.style(value) == node.DoubleQuotedScalar
  assert node.span(document)
    == node.Span(start: node.Position(1, 1), end: node.Position(1, 12))
}

pub fn get_retrieves_nested_mapping_values_test() {
  let assert Ok(document) = yaml.parse_node("job:\n  script: [gleam, test]\n")
  let assert option.Some(script) =
    node.get(document, [
      node.Key("job"),
      node.Key("script"),
    ])
  let assert option.Some(command) = node.get(script, [node.Index(0)])

  assert node.as_string(command) == option.Some("gleam")
}

pub fn parse_node_tracks_flow_collection_style_and_span_test() {
  let assert Ok(document) = yaml.parse_node("commands: [gleam, test]\n")
  let assert option.Some(commands) = node.get(document, [node.Key("commands")])

  assert node.style(commands) == node.FlowSequence
  assert node.span(commands)
    == node.Span(start: node.Position(1, 11), end: node.Position(1, 24))
}

pub fn parse_node_tracks_block_scalar_style_and_span_test() {
  let assert Ok(document) = yaml.parse_node("script: |\n  gleam test\n")
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

  let rendered = yaml.to_string(document)

  assert rendered == Ok("name: yum\ncommands:\n  - gleam\n  - test")
}

pub fn to_string_validates_emitted_yaml_test() {
  let document =
    builder.mapping([
      #(builder.string("name"), builder.string("yum")),
    ])

  let assert Ok(rendered) = yaml.to_string(document)

  assert yaml.parse_node(rendered) |> result.is_ok()
}

pub fn get_index_rejects_negative_indexes_test() {
  let document =
    builder.sequence([
      builder.string("first"),
    ])

  assert node.get_index(document, -1) == option.None
}

pub fn parse_node_with_diagnostics_warns_for_duplicate_keys_test() {
  let assert Ok(yaml.Parsed(value: document, diagnostics: [warning])) =
    yaml.parse_node_with_diagnostics("name: one\nname: two\n")

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
  let assert Ok(yaml.Parsed(diagnostics: [warning], ..)) =
    yaml.parse_node_with_diagnostics("job:\n  script: one\n  script: two\n")

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
