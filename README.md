# yum

[![Package Version](https://img.shields.io/hexpm/v/yum)](https://hex.pm/packages/yum)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/yum/)

```sh
gleam add yum@1
```
```gleam
import yum/yaml

pub fn parse_document(input: String) {
  yaml.parse(input)
  // -> Ok(Yaml(...))
}
```

For tooling-oriented use cases, parse an opaque node and interact through the
accessor API:

```gleam
import gleam/option.{type Option, None}
import yum/yaml
import yum/yaml/node.{type YamlNode}

pub fn image(input: String) -> Option(YamlNode) {
  case yaml.parse_node(input) {
    Ok(document) -> document |> node.get([node.Key("image")])
    Error(_) -> None
  }
  // -> Some(YamlNode(...))
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
  yaml.decode(input, using: decode.field("name", decode.string))
  // -> Ok("yum")
}

pub fn build_document() {
  builder.mapping([
    #(builder.string("name"), builder.string("yum")),
  ])
  |> yaml.to_string()
  // -> Ok("name: yum")
}
```

For tooling, parse syntax first and then resolve the YAML document. The resolver
keeps non-fatal warnings such as duplicate mapping keys as typed diagnostics:

```gleam
import yum/yaml
import yum/yaml/resolved

const input = "
name: yum
name: yaml
"

pub fn check() {
  yaml.load_node(input)
  // -> Ok(Resolved(...))
}

pub fn diagnostics() {
  let assert Ok(document) = yaml.load_node(input)

  resolved.diagnostics(document)
  // -> [DuplicateMappingKey(...)]
}
```

Further documentation can be found at <https://hexdocs.pm/yum>.

## Development

```sh
gleam test  # Run the tests
```
