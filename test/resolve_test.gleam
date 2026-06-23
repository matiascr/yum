import gleam/list
import gleam/option
import gleam/result
import yaml_helpers as helpers
import yum/yaml
import yum/yaml/builder
import yum/yaml/diagnostic
import yum/yaml/node

pub fn resolve_returns_resolved_document_test() {
  let assert Ok(document) = yaml.parse("name: yum\n")
  let assert Ok(resolved_document) = yaml.resolve(document)

  assert yaml.diagnostics(resolved_document) == []
  assert yaml.root(resolved_document) == yaml.root(document)
}

pub fn resolve_preserves_non_fatal_diagnostics_test() {
  let assert Ok(document) = yaml.parse("name: one\nname: two\n")
  let assert Ok(resolved_document) = yaml.resolve(document)
  let assert [warning] = yaml.diagnostics(resolved_document)

  assert diagnostic.severity(warning) == diagnostic.Warning
  assert diagnostic.message(warning) == "Duplicate mapping key `name`"
  assert diagnostic.has_errors(yaml.diagnostics(resolved_document)) == False
}

pub fn parse_then_resolve_returns_queryable_yaml_test() {
  let assert Ok(document) = yaml.parse("job:\n  script: test\n")
  let assert Ok(resolved_document) = yaml.resolve(document)
  let assert option.Some(script) =
    resolved_document
    |> yaml.get([node.Key("job"), node.Key("script")])

  assert node.as_string(script) == Ok("test")
}

pub fn raw_yaml_is_queryable_test() {
  let assert Ok(document) = yaml.parse("job:\n  script: test\n")
  let assert option.Some(script) =
    document
    |> yaml.get([node.Key("job"), node.Key("script")])

  assert node.as_string(script) == Ok("test")
}

pub fn resolve_is_idempotent_test() {
  let assert Ok(document) = yaml.parse("name: yum\n")
  let assert Ok(document) = yaml.resolve(document)
  let assert Ok(document) = yaml.resolve(document)

  assert yaml.diagnostics(document) == []
}

pub fn parse_stream_can_resolve_each_document_test() {
  let assert Ok(documents) = yaml.parse_stream("---\none\n---\ntwo\n")
  let assert Ok(documents) = documents |> list.map(yaml.resolve) |> result.all()

  assert list.length(documents) == 2
  assert list.map(documents, yaml.diagnostics) == [[], []]
}

pub fn resolve_expands_declared_tag_handles_test() {
  let assert Ok(document) =
    yaml.parse("%TAG !e! tag:example.com,2026:\n---\nvalue: !e!thing hello\n")
  let assert Ok(resolved_document) = yaml.resolve(document)
  let assert option.Some(value) =
    resolved_document
    |> yaml.get([node.Key("value")])

  assert node.tag(value) == option.Some("tag:example.com,2026:thing")
}

pub fn resolve_expands_core_tag_handles_test() {
  let assert Ok(document) = yaml.parse("value: !!str 123\n")
  let assert Ok(resolved_document) = yaml.resolve(document)
  let assert option.Some(value) =
    resolved_document
    |> yaml.get([node.Key("value")])

  assert node.tag(value) == option.Some("tag:yaml.org,2002:str")
  assert node.as_int(value) == Ok(123)
}

pub fn resolve_expands_primary_tag_handles_test() {
  let assert Ok(document) =
    yaml.parse("%TAG ! tag:example.com,2026:\n---\nvalue: !Thing hello\n")
  let assert Ok(resolved_document) = yaml.resolve(document)
  let assert option.Some(value) =
    resolved_document
    |> yaml.get([node.Key("value")])

  assert node.tag(value) == option.Some("tag:example.com,2026:Thing")
}

pub fn resolve_preserves_default_local_tags_test() {
  let assert Ok(document) = yaml.parse("value: !Thing hello\n")
  let assert Ok(resolved_document) = yaml.resolve(document)
  let assert option.Some(value) =
    resolved_document
    |> yaml.get([node.Key("value")])

  assert node.tag(value) == option.Some("!Thing")
}

pub fn resolve_expands_verbatim_tags_test() {
  let assert Ok(document) =
    yaml.parse("value: !<tag:example.com,2026:thing> hello\n")
  let assert Ok(resolved_document) = yaml.resolve(document)
  let assert option.Some(value) =
    resolved_document
    |> yaml.get([node.Key("value")])

  assert node.tag(value) == option.Some("tag:example.com,2026:thing")
}

pub fn resolve_rejects_unknown_tag_handles_test() {
  let assert Ok(document) = yaml.parse("value: !e!thing hello\n")
  let assert option.Some(value) =
    document
    |> yaml.get([node.Key("value")])

  let assert Error([error]) = yaml.resolve(document)

  assert error
    == diagnostic.UnknownTagHandle(handle: "!e!", span: node.span(value))
  assert diagnostic.severity(error) == diagnostic.DiagnosticError
  assert diagnostic.message(error) == "Unknown tag handle `!e!`"
}

pub fn resolve_rejects_invalid_tag_directives_test() {
  let assert Ok(document) = yaml.parse("%TAG !e!\n---\nvalue\n")
  let assert [directive] = yaml.directives(document)
  let yaml.Directive(span:, ..) = directive

  let assert Error([error]) = yaml.resolve(document)

  assert error == diagnostic.InvalidTagDirective(span:)
  assert diagnostic.severity(error) == diagnostic.DiagnosticError
  assert diagnostic.message(error) == "Invalid %TAG directive"
}

pub fn diagnostic_helpers_split_warnings_and_errors_test() {
  let assert Ok(document) = yaml.parse("name: one\nname: two\n")
  let assert Ok(resolved_document) = yaml.resolve(document)
  let diagnostics = yaml.diagnostics(resolved_document)

  assert diagnostic.errors(diagnostics) == []
  assert diagnostic.warnings(diagnostics) == diagnostics
}

pub fn resolve_accepts_aliases_for_prior_anchors_test() {
  let document =
    builder.sequence([
      builder.string("value") |> node.with_anchor("base"),
      builder.null() |> node.with_alias("base"),
    ])

  let assert Ok(resolved_document) =
    document
    |> yaml.from_node()
    |> yaml.resolve()

  assert yaml.diagnostics(resolved_document) == []
}

pub fn resolve_rejects_unknown_aliases_test() {
  let document = builder.null() |> node.with_alias("missing")

  let assert Error([error]) =
    document
    |> yaml.from_node()
    |> yaml.resolve()

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

  let assert Error([error]) =
    document
    |> yaml.from_node()
    |> yaml.resolve()

  assert error
    == diagnostic.UnknownAlias(alias: "base", span: node.synthetic_span())
}

pub fn node_tracks_anchor_and_alias_metadata_test() {
  let assert Ok(document) =
    helpers.parse_node("base: &base value\ncopy: *base\n")
  let assert option.Some(base) = node.get(document, [node.Key("base")])
  let assert option.Some(copy) = node.get(document, [node.Key("copy")])

  assert node.anchor(base) == option.Some("base")
  assert node.as_string(base) == Ok("value")
  assert node.alias(copy) == option.Some("base")
}

pub fn resolve_accepts_known_aliases_from_parsed_yaml_test() {
  let assert Ok(document) = yaml.parse("base: &base value\ncopy: *base\n")

  assert yaml.resolve(document) |> result.is_ok()
}

pub fn resolve_rejects_unknown_aliases_from_parsed_yaml_test() {
  let assert Ok(document) = yaml.parse("copy: *base\n")
  let assert Error([error]) = yaml.resolve(document)

  assert error
    == diagnostic.UnknownAlias(
      alias: "base",
      span: node.Span(start: node.Position(1, 7), end: node.Position(1, 12)),
    )
}

pub fn node_tracks_flow_aliases_test() {
  let assert Ok(document) = helpers.parse_node("items: [&base value, *base]\n")
  let assert option.Some(items) = node.get(document, [node.Key("items")])
  let assert node.Sequence([base, copy]) = node.kind(items)

  assert node.anchor(base) == option.Some("base")
  assert node.alias(copy) == option.Some("base")
}

pub fn node_tracks_local_tag_metadata_test() {
  let assert Ok(document) = helpers.parse_node("value: !Thing hello\n")
  let assert option.Some(value) = node.get(document, [node.Key("value")])

  assert node.tag(value) == option.Some("Thing")
  assert node.as_string(value) == Ok("hello")
}

pub fn node_tracks_core_tag_metadata_test() {
  let assert Ok(document) = helpers.parse_node("value: !!str 123\n")
  let assert option.Some(value) = node.get(document, [node.Key("value")])

  assert node.tag(value) == option.Some("!str")
  assert node.as_int(value) == Ok(123)
}

pub fn node_tracks_verbatim_tag_metadata_test() {
  let assert Ok(document) =
    helpers.parse_node("value: !<tag:example.com,2026:thing> hello\n")
  let assert option.Some(value) = node.get(document, [node.Key("value")])

  assert node.tag(value) == option.Some("<tag:example.com,2026:thing>")
  assert node.as_string(value) == Ok("hello")
}

pub fn node_tracks_tag_and_anchor_metadata_test() {
  let assert Ok(document) = helpers.parse_node("value: !Thing &base hello\n")
  let assert option.Some(value) = node.get(document, [node.Key("value")])

  assert node.tag(value) == option.Some("Thing")
  assert node.anchor(value) == option.Some("base")
}
