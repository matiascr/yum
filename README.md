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
import yum/yaml/node.{type YamlNode}

pub fn image(input: String) -> Option(YamlNode) {
  case yaml.parse(input) {
    Ok(document) -> document |> yaml.get([node.Key("image")])
    Error(_) -> None
  }
  // -> Some(YamlNode(...))
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

## Development

```sh
gleam test  # Run the tests
```
