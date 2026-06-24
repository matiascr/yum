# yum

[![Package Version](https://img.shields.io/hexpm/v/yum)](https://hex.pm/packages/yum)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/yum/)

```sh
gleam add yum@1
```
```gleam
import yum/yaml

pub fn parse_yaml(input: String) {
  yaml.parse(input)
  // -> Ok(Yaml(...))
}
```

[`yaml.parse`](https://hexdocs.pm/yum/yum/yaml.html#parse) returns an opaque
YAML document. You can inspect it directly or pipe it through
[`yaml.resolve`](https://hexdocs.pm/yum/yum/yaml.html#resolve) to run semantic
YAML checks:

```gleam
import gleam/option.{type Option, None}
import yum/yaml
import yum/yaml/node.{type Node}

pub fn image(input: String) -> Option(Node) {
  case yaml.parse(input) {
    Ok(document) -> document |> yaml.get([node.Key("image")])
    Error(_) -> None
  }
  // -> Some(Node(...))
}

pub fn check(input: String) {
  let assert Ok(document) = yaml.parse(input)

  document
  |> yaml.resolve()
  // -> Ok(Yaml(...))
}
```

YAML can also be decoded with
[`gleam/dynamic/decode`](https://hexdocs.pm/gleam_stdlib/gleam/dynamic/decode.html),
or built and emitted with
[`yum/yaml/builder`](https://hexdocs.pm/yum/yum/yaml/builder.html):

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

  yaml.decode(input, using: decoder)
  // -> Ok("yum")
}

pub fn build_document() {
  builder.mapping([
    #(builder.string("name"), builder.string("yum")),
  ])
  |> yaml.from_node()
  |> yaml.to_string()
  // -> "name: yum"
}
```

The resolver keeps non-fatal warnings such as duplicate mapping keys as typed
diagnostics:

```gleam
import yum/yaml

const input = "
name: yum
name: yaml
"

pub fn diagnostics() {
  let assert Ok(document) = yaml.parse(input)
  let assert Ok(document) = yaml.resolve(document)

  yaml.diagnostics(document)
  // -> [DuplicateMappingKey(...)]
}
```

Further documentation can be found at <https://hexdocs.pm/yum>.

## Public API

The stable 1.0 API is intentionally small:

- [`yum/yaml`](https://hexdocs.pm/yum/yum/yaml.html) parses, resolves, queries,
  decodes, and emits YAML documents.
- [`yum/yaml/node`](https://hexdocs.pm/yum/yum/yaml/node.html) inspects YAML
  nodes, including kind, span, style, tags, anchors, aliases, paths, mapping
  keys, and mapping values.
- [`yum/yaml/builder`](https://hexdocs.pm/yum/yum/yaml/builder.html) builds
  synthetic YAML node trees in Gleam code.
- [`yum/yaml/diagnostic`](https://hexdocs.pm/yum/yum/yaml/diagnostic.html)
  exposes typed resolver diagnostics.
- [`yum/yaml/error`](https://hexdocs.pm/yum/yum/yaml/error.html) exposes parse
  errors, messages, and source spans.

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
input
|> yaml.parse()
|> result.then(yaml.resolve)
// -> Ok(Yaml(...))
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
