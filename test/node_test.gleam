import gleam/dynamic/decode
import gleam/option
import gleam/result
import yum/yaml
import yum/yaml/builder
import yum/yaml/node

pub fn parse_node_exposes_kind_and_accessors_test() {
  let assert Ok(document) = yaml.parse_node("name: \"yum\"\n")
  let assert node.Mapping(entries) = node.kind(document)
  let assert [#(key, value)] = entries

  assert node.as_string(key) == option.Some("name")
  assert node.as_string(value) == option.Some("yum")
  assert node.style(document) == node.Synthetic
  assert node.span(document) == node.synthetic_span()
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
