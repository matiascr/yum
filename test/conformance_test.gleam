import gleam/list
import gleam/option
import gleam/result
import yum/yaml
import yum/yaml/diagnostic
import yum/yaml/error
import yum/yaml/node

pub fn stream_directives_are_scoped_to_each_document_test() {
  let input =
    "%TAG !e! tag:example.com,2026:
---
value: !e!one hello
...
%TAG !e! tag:example.org,2026:
---
value: !e!two world
"

  let assert Ok(documents) = yaml.parse_stream(input)
  let assert Ok(documents) = documents |> list.map(yaml.resolve) |> result.all()
  let assert [first, second] = documents
  let assert option.Some(first_value) = first |> yaml.get([node.Key("value")])
  let assert option.Some(second_value) = second |> yaml.get([node.Key("value")])

  assert node.tag(first_value) == option.Some("tag:example.com,2026:one")
  assert node.tag(second_value) == option.Some("tag:example.org,2026:two")
  assert yaml.diagnostics(first) == []
  assert yaml.diagnostics(second) == []
}

pub fn explicit_complex_mapping_keys_parse_as_nodes_test() {
  let input =
    "? [region, us-east-1]
: [web, worker]
? {tier: backend}
: active
"

  let assert Ok(document) = yaml.parse(input)
  let assert Ok(entries) = document |> yaml.root() |> node.as_mapping()
  let assert [#(sequence_key, sequence_value), #(mapping_key, mapping_value)] =
    entries

  assert sequence_key |> node.as_sequence() |> result.map(list.length) == Ok(2)
  assert sequence_value |> node.as_sequence() |> result.map(list.length)
    == Ok(2)
  assert mapping_key |> node.as_mapping() |> result.map(list.length) == Ok(1)
  assert node.as_string(mapping_value) == Ok("active")
}

pub fn block_scalar_chomping_modes_match_yaml_expectations_test() {
  let input =
    "literal_strip: |-
  line one
  line two
literal_clip: |
  line one
  line two
folded_keep: >+
  line one

  line two

"

  let assert Ok(document) = yaml.parse(input)
  let assert option.Some(literal_strip) =
    document |> yaml.get([node.Key("literal_strip")])
  let assert option.Some(literal_clip) =
    document |> yaml.get([node.Key("literal_clip")])
  let assert option.Some(folded_keep) =
    document |> yaml.get([node.Key("folded_keep")])

  assert node.as_string(literal_strip) == Ok("line one\nline two")
  assert node.as_string(literal_clip) == Ok("line one\nline two\n")
  assert node.as_string(folded_keep) == Ok("line one\nline two\n")
}

pub fn comments_do_not_change_parsed_values_test() {
  let input =
    "# leading comment
name: yum # trailing comment
jobs:
  # nested comment
  - test
  - build # another trailing comment
"

  let assert Ok(document) = yaml.parse(input)
  let assert option.Some(name) = document |> yaml.get([node.Key("name")])
  let assert option.Some(second_job) =
    document |> yaml.get([node.Key("jobs"), node.Index(1)])

  assert node.as_string(name) == Ok("yum")
  assert node.as_string(second_job) == Ok("build")
}

pub fn github_actions_style_merge_keys_resolve_to_queryable_values_test() {
  let input =
    "defaults: &defaults
  runs-on: ubuntu-latest
  timeout-minutes: 10
  steps:
    - uses: actions/checkout@v4
jobs:
  test:
    <<: *defaults
    timeout-minutes: 15
    steps:
      - uses: actions/checkout@v4
      - run: gleam test
"

  let assert Ok(document) = yaml.parse(input)
  let assert Ok(document) = yaml.resolve(document)
  let assert option.Some(runner) =
    document
    |> yaml.get([node.Key("jobs"), node.Key("test"), node.Key("runs-on")])
  let assert option.Some(timeout) =
    document
    |> yaml.get([
      node.Key("jobs"),
      node.Key("test"),
      node.Key("timeout-minutes"),
    ])
  let assert option.Some(run) =
    document
    |> yaml.get([
      node.Key("jobs"),
      node.Key("test"),
      node.Key("steps"),
      node.Index(1),
      node.Key("run"),
    ])

  assert node.as_string(runner) == Ok("ubuntu-latest")
  assert node.as_int(timeout) == Ok(15)
  assert node.as_string(run) == Ok("gleam test")
  assert document
    |> yaml.get([node.Key("jobs"), node.Key("test"), node.Key("<<")])
    == option.None
}

pub fn duplicate_keys_are_reported_with_source_locations_test() {
  let input =
    "name: first
nested:
  image: ubuntu
  image: alpine
"

  let assert Ok(document) = yaml.parse(input)
  let assert Ok(document) = yaml.resolve(document)
  let assert [warning] = yaml.diagnostics(document)

  assert warning
    == diagnostic.DuplicateMappingKey(
      key: "image",
      duplicate: span(4, 3, 4, 9),
      original: span(3, 3, 3, 9),
    )
  assert diagnostic.severity(warning) == diagnostic.Warning
  assert diagnostic.related(warning)
    == [diagnostic.FirstMappingKey(span: span(3, 3, 3, 9))]
}

pub fn invalid_yaml_parse_errors_have_public_messages_and_spans_test() {
  let assert Error(parse_error) =
    yaml.parse("jobs:\n  test:\n    steps:\n   - run: gleam test\n")

  assert error.message(parse_error) == "Unexpected YAML token `-`"
  let assert option.Some(_) = error.span(parse_error)
}

pub fn invalid_aliases_are_resolver_diagnostics_not_parse_errors_test() {
  let assert Ok(document) = yaml.parse("copy: *missing\n")
  let assert Error([resolve_error]) = yaml.resolve(document)

  assert resolve_error
    == diagnostic.UnknownAlias(alias: "missing", span: span(1, 7, 1, 15))
  assert diagnostic.message(resolve_error) == "Unknown alias `missing`"
  assert diagnostic.severity(resolve_error) == diagnostic.DiagnosticError
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
