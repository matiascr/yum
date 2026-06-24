# yum

```sh
gleam add yum@1
```
```gleam
import gleam/option
import yum/yaml
import yum/yaml/node

pub fn parse_yaml() {
  let assert Ok(document) = yaml.parse("name: yum")

  let name =
    document
    |> yaml.get([node.Key("name")])
    |> option.map(node.as_string)

  assert name == option.Some(Ok("yum"))
}
```

`yaml.parse` returns an opaque YAML document. You can inspect it directly or
pipe it through `yaml.resolve` to run semantic YAML checks:

```gleam
import gleam/option.{type Option, None, Some}
import yum/yaml
import yum/yaml/node.{type Node}

pub fn image(input: String) -> Option(Node) {
  case yaml.parse(input) {
    Ok(document) -> document |> yaml.get([node.Key("image")])
    Error(_) -> None
  }
}

pub fn image_example() {
  let assert Some(image) = image("image: gleam:latest")

  assert node.as_string(image) == Ok("gleam:latest")
}

pub fn check(input: String) {
  let assert Ok(document) = yaml.parse(input)

  let assert Ok(_) = document |> yaml.resolve()
}
```

YAML can also be decoded with `gleam/dynamic/decode`, or built and emitted with
`yum/yaml/builder`:

```gleam
import gleam/dynamic/decode
import yum/yaml
import yum/yaml/builder

const input = "name: yum"

pub fn decode_name() {
  let decoder = {
    use name <- decode.field("name", decode.string)
    decode.success(name)
  }

  assert yaml.decode(input, using: decoder) == Ok("yum")
}

pub fn build_document() {
  let output =
    builder.mapping([
      #(builder.string("name"), builder.string("yum")),
    ])
    |> yaml.from_node()
    |> yaml.to_string()

  assert output == "name: yum"
}
```

The resolver keeps non-fatal warnings such as duplicate mapping keys as typed
diagnostics:

```gleam
import gleam/list
import yum/yaml
import yum/yaml/diagnostic

const input = "
name: yum
name: yaml
"

pub fn diagnostics() {
  let assert Ok(document) = yaml.parse(input)
  let assert Ok(document) = yaml.resolve(document)

  let messages =
    document
    |> yaml.diagnostics()
    |> list.map(diagnostic.message)

  assert messages == ["Duplicate mapping key `name`"]
}
```

Further documentation can be found on HexDocs after publishing.

## Public API

The stable 1.0 API is intentionally small:

- `yum/yaml` parses, resolves, queries, decodes, and emits YAML documents.
- `yum/yaml/node` inspects YAML nodes, including kind, span, style, tags,
  anchors, aliases, paths, mapping keys, and mapping values.
- `yum/yaml/builder` builds synthetic YAML node trees in Gleam code.
- `yum/yaml/diagnostic` exposes typed resolver diagnostics.
- `yum/yaml/error` exposes parse errors, messages, and source spans.

Lexer, parser, resolver, emitter, token, dynamic, and document internals are not
part of the public API.

## YAML support

`yum` targets YAML 1.2-style configuration files with a tooling-oriented API. It
is suitable for parsing and inspecting common configuration files such as GitHub
Actions workflows, package metadata, and Kubernetes-style manifests.

The 1.0 support surface includes:

- block and flow sequences and mappings
- plain, single-quoted, double-quoted, literal block, and folded block scalars
- document streams with `---` and `...` markers
- comments in parsed input
- anchors, aliases, local tags, verbatim tags, and `%TAG` directives
- merge keys (`<<`) as a pragmatic compatibility feature
- source spans and source styles
- typed parse errors and typed resolver diagnostics
- lookup by mapping key or sequence index
- mapping key/value extraction
- decoding through `gleam/dynamic/decode`
- builder functions and deterministic emission

The semantic resolver is intentionally separate from syntax parsing:

```gleam
let assert Ok(_) =
  input
  |> yaml.parse()
  |> result.then(yaml.resolve)
```

Current limits:

- `yum` does not claim full YAML Test Suite compliance yet.
- Comments are accepted in input, but not preserved for round-trip editing.
- Tags are expanded and exposed, but tags do not currently force scalar casts.
- Selectable schemas such as failsafe, JSON, and core are not exposed yet.
- The emitter is deterministic, but it is not a formatter and does not preserve
  the original source layout.

## Development

```sh
gleam test --target erlang
gleam test --target javascript
gleam format --check src test
gleam docs build
```
