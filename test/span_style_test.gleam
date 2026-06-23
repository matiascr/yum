import gleam/option
import yaml_helpers as helpers
import yum/yaml/node

pub fn node_tracks_scalar_styles_and_spans_test() {
  let assert Ok(plain) = helpers.parse_node("plain")
  let assert Ok(single) = helpers.parse_node("'value'")
  let assert Ok(double) = helpers.parse_node("\"value\"")

  assert node.style(plain) == node.PlainScalar
  assert node.span(plain) == span(1, 1, 1, 6)
  assert node.style(single) == node.SingleQuotedScalar
  assert node.span(single) == span(1, 1, 1, 7)
  assert node.style(double) == node.DoubleQuotedScalar
  assert node.span(double) == span(1, 1, 1, 8)
}

pub fn node_tracks_block_sequence_style_and_span_test() {
  let assert Ok(document) = helpers.parse_node("- one\n- two\n")

  assert node.style(document) == node.BlockSequence
  assert node.span(document) == span(1, 1, 2, 6)
}

pub fn node_tracks_block_mapping_style_and_span_test() {
  let assert Ok(document) = helpers.parse_node("one: 1\ntwo: 2\n")

  assert node.style(document) == node.BlockMapping
  assert node.span(document) == span(1, 1, 2, 7)
}

pub fn node_tracks_flow_sequence_style_and_span_test() {
  let assert Ok(document) = helpers.parse_node("[one, two]")

  assert node.style(document) == node.FlowSequence
  assert node.span(document) == span(1, 1, 1, 11)
}

pub fn node_tracks_flow_mapping_style_and_span_test() {
  let assert Ok(document) = helpers.parse_node("{one: 1, two: 2}")

  assert node.style(document) == node.FlowMapping
  assert node.span(document) == span(1, 1, 1, 17)
}

pub fn node_tracks_block_scalar_styles_and_spans_test() {
  let assert Ok(literal_document) =
    helpers.parse_node("script: |\n  gleam test\n")
  let assert option.Some(literal) =
    node.get(literal_document, [node.Key("script")])
  let assert Ok(folded_document) =
    helpers.parse_node("script: >\n  gleam\n  test\n")
  let assert option.Some(folded) =
    node.get(folded_document, [node.Key("script")])

  assert node.style(literal) == node.LiteralBlockScalar
  assert node.span(literal) == span(1, 9, 2, 13)
  assert node.style(folded) == node.FoldedBlockScalar
  assert node.span(folded) == span(1, 9, 3, 7)
}

fn span(
  start_row: Int,
  start_column: Int,
  end_row: Int,
  end_column: Int,
) -> node.Span {
  node.Span(
    start: node.Position(start_row, start_column),
    end: node.Position(end_row, end_column),
  )
}
