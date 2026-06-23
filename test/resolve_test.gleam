import gleam/list
import gleam/option
import gleam/result
import yum/yaml
import yum/yaml/builder
import yum/yaml/diagnostic
import yum/yaml/node
import yum/yaml/resolved

pub fn resolve_returns_resolved_document_test() {
  let assert Ok(document) = yaml.parse_node("name: yum\n")
  let assert Ok(resolved_document) = yaml.resolve(document)

  assert resolved.diagnostics(resolved_document) == []
  assert resolved.root(resolved_document) == document
}

pub fn resolve_preserves_non_fatal_diagnostics_test() {
  let assert Ok(document) = yaml.parse_node("name: one\nname: two\n")
  let assert Ok(resolved_document) = yaml.resolve(document)
  let assert [warning] = resolved.diagnostics(resolved_document)

  assert diagnostic.severity(warning) == diagnostic.Warning
  assert diagnostic.message(warning) == "Duplicate mapping key `name`"
  assert diagnostic.has_errors(resolved.diagnostics(resolved_document)) == False
}

pub fn load_node_parses_and_resolves_test() {
  let assert Ok(resolved_document) = yaml.load_node("job:\n  script: test\n")
  let assert option.Some(script) =
    resolved_document
    |> resolved.root
    |> node.get([node.Key("job"), node.Key("script")])

  assert node.as_string(script) == Ok("test")
}

pub fn load_node_stream_resolves_each_document_test() {
  let assert Ok(documents) = yaml.load_node_stream("---\none\n---\ntwo\n")

  assert list.length(documents) == 2
  assert list.map(documents, resolved.diagnostics) == [[], []]
}

pub fn diagnostic_helpers_split_warnings_and_errors_test() {
  let assert Ok(document) = yaml.parse_node("name: one\nname: two\n")
  let assert Ok(resolved_document) = yaml.resolve(document)
  let diagnostics = resolved.diagnostics(resolved_document)

  assert diagnostic.errors(diagnostics) == []
  assert diagnostic.warnings(diagnostics) == diagnostics
}

pub fn resolve_accepts_aliases_for_prior_anchors_test() {
  let document =
    builder.sequence([
      builder.string("value") |> node.with_anchor("base"),
      builder.null() |> node.with_alias("base"),
    ])

  let assert Ok(resolved_document) = yaml.resolve(document)

  assert resolved.diagnostics(resolved_document) == []
}

pub fn resolve_rejects_unknown_aliases_test() {
  let document = builder.null() |> node.with_alias("missing")

  let assert Error([error]) = yaml.resolve(document)

  assert error
    == diagnostic.UnknownAlias(alias: "missing", span: node.synthetic_span())
  assert diagnostic.severity(error) == diagnostic.DiagnosticError
  assert diagnostic.message(error) == "Unknown alias `missing`"
  assert diagnostic.has_errors([error]) == True
}

pub fn resolve_rejects_aliases_before_anchors_test() {
  let document =
    builder.sequence([
      builder.null() |> node.with_alias("base"),
      builder.string("value") |> node.with_anchor("base"),
    ])

  let assert Error([error]) = yaml.resolve(document)

  assert error
    == diagnostic.UnknownAlias(alias: "base", span: node.synthetic_span())
}

pub fn parse_node_tracks_anchor_and_alias_metadata_test() {
  let assert Ok(document) = yaml.parse_node("base: &base value\ncopy: *base\n")
  let assert option.Some(base) = node.get(document, [node.Key("base")])
  let assert option.Some(copy) = node.get(document, [node.Key("copy")])

  assert node.anchor(base) == option.Some("base")
  assert node.as_string(base) == Ok("value")
  assert node.alias(copy) == option.Some("base")
}

pub fn resolve_accepts_known_aliases_from_parsed_yaml_test() {
  let assert Ok(document) = yaml.parse_node("base: &base value\ncopy: *base\n")

  assert yaml.resolve(document) |> result.is_ok()
}

pub fn load_node_rejects_unknown_aliases_from_parsed_yaml_test() {
  let assert Error(yaml.LoadResolveError([error])) =
    yaml.load_node("copy: *base\n")

  assert error
    == diagnostic.UnknownAlias(
      alias: "base",
      span: node.Span(start: node.Position(1, 7), end: node.Position(1, 12)),
    )
}

pub fn parse_node_tracks_flow_aliases_test() {
  let assert Ok(document) = yaml.parse_node("items: [&base value, *base]\n")
  let assert option.Some(items) = node.get(document, [node.Key("items")])
  let assert node.Sequence([base, copy]) = node.kind(items)

  assert node.anchor(base) == option.Some("base")
  assert node.alias(copy) == option.Some("base")
}

pub fn parse_node_tracks_local_tag_metadata_test() {
  let assert Ok(document) = yaml.parse_node("value: !Thing hello\n")
  let assert option.Some(value) = node.get(document, [node.Key("value")])

  assert node.tag(value) == option.Some("Thing")
  assert node.as_string(value) == Ok("hello")
}

pub fn parse_node_tracks_core_tag_metadata_test() {
  let assert Ok(document) = yaml.parse_node("value: !!str 123\n")
  let assert option.Some(value) = node.get(document, [node.Key("value")])

  assert node.tag(value) == option.Some("!str")
  assert node.as_int(value) == Ok(123)
}

pub fn parse_node_tracks_verbatim_tag_metadata_test() {
  let assert Ok(document) =
    yaml.parse_node("value: !<tag:example.com,2026:thing> hello\n")
  let assert option.Some(value) = node.get(document, [node.Key("value")])

  assert node.tag(value) == option.Some("<tag:example.com,2026:thing>")
  assert node.as_string(value) == Ok("hello")
}

pub fn parse_node_tracks_tag_and_anchor_metadata_test() {
  let assert Ok(document) = yaml.parse_node("value: !Thing &base hello\n")
  let assert option.Some(value) = node.get(document, [node.Key("value")])

  assert node.tag(value) == option.Some("Thing")
  assert node.anchor(value) == option.Some("base")
}
