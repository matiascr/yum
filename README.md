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
  // -> Ok("name: yum")
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

## YAML support

`yum` targets YAML 1.2-style configuration files with a tooling-oriented API.
It currently supports:

- block and flow sequences and mappings
- plain, single-quoted, double-quoted, literal block, and folded block scalars
- document streams with `---` and `...` markers
- comments in parsed input
- anchors, aliases, local tags, verbatim tags, and `%TAG` directives
- merge keys (`<<`) as a pragmatic compatibility feature
- spans, styles, typed diagnostics, decoding, building, and deterministic
  emission

The semantic resolver is intentionally separate from syntax parsing:

```gleam
input
|> yaml.parse()
|> result.then(yaml.resolve)
// -> Ok(Yaml(...))
```

Known limitations before a full compliance claim:

- Tags are expanded, but not every YAML tag URI edge case is validated.
- Comments are accepted in input, but not preserved for round-trip editing.
- `yum` does not yet expose selectable schemas such as failsafe, JSON, or core.

## Development

```sh
gleam test  # Run the tests
```
