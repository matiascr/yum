import gleam/dynamic/decode
import gleam/option
import yum/yaml
import yum/yaml/builder
import yum/yaml/node

type Package {
  Package(name: String, version: String, dependencies: List(String))
}

pub fn github_actions_workflow_can_be_resolved_and_queried_test() {
  let input =
    "name: CI
on:
  push:
    branches: [main]
  pull_request:
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Test
        run: gleam test
"

  let assert Ok(document) = yaml.parse(input)
  let assert Ok(document) = yaml.resolve(document)
  let assert option.Some(workflow_name) =
    document
    |> yaml.get([node.Key("name")])
  let assert option.Some(runner) =
    document
    |> yaml.get([node.Key("jobs"), node.Key("test"), node.Key("runs-on")])
  let assert option.Some(run) =
    document
    |> yaml.get([
      node.Key("jobs"),
      node.Key("test"),
      node.Key("steps"),
      node.Index(1),
      node.Key("run"),
    ])

  assert node.as_string(workflow_name) == Ok("CI")
  assert node.as_string(runner) == Ok("ubuntu-latest")
  assert node.as_string(run) == Ok("gleam test")
  assert yaml.diagnostics(document) == []
}

pub fn kubernetes_deployment_can_be_queried_by_path_test() {
  let input =
    "apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
spec:
  replicas: 3
  template:
    spec:
      containers:
        - name: app
          image: ghcr.io/example/web:latest
          ports:
            - containerPort: 8080
"

  let assert Ok(document) = yaml.parse(input)
  let assert option.Some(image) =
    document
    |> yaml.get([
      node.Key("spec"),
      node.Key("template"),
      node.Key("spec"),
      node.Key("containers"),
      node.Index(0),
      node.Key("image"),
    ])
  let assert option.Some(port) =
    document
    |> yaml.get([
      node.Key("spec"),
      node.Key("template"),
      node.Key("spec"),
      node.Key("containers"),
      node.Index(0),
      node.Key("ports"),
      node.Index(0),
      node.Key("containerPort"),
    ])

  assert node.as_string(image) == Ok("ghcr.io/example/web:latest")
  assert node.as_int(port) == Ok(8080)
}

pub fn indented_plain_scalar_continuations_are_folded_test() {
  let input =
    "metadata:
  description: Deploys the web service
    across the production cluster
"

  let assert Ok(document) = yaml.parse(input)
  let assert option.Some(description) =
    document
    |> yaml.get([node.Key("metadata"), node.Key("description")])

  assert node.as_string(description)
    == Ok("Deploys the web service across the production cluster")
}

pub fn package_metadata_can_be_decoded_into_a_gleam_type_test() {
  let input =
    "package:
  name: yum
  version: 1.0.0
  dependencies:
    - gleam_stdlib
    - nibble
"
  let decoder = {
    use name <- decode.field("name", decode.string)
    use version <- decode.field("version", decode.string)
    use dependencies <- decode.field(
      "dependencies",
      decode.list(of: decode.string),
    )
    decode.success(Package(name:, version:, dependencies:))
  }

  let package_decoder = {
    use package <- decode.field("package", decoder)
    decode.success(package)
  }

  assert yaml.decode(input, using: package_decoder)
    == Ok(
      Package(name: "yum", version: "1.0.0", dependencies: [
        "gleam_stdlib",
        "nibble",
      ]),
    )
}

pub fn builder_output_can_be_emitted_and_parsed_again_test() {
  let document =
    builder.mapping([
      #(builder.string("name"), builder.string("yum")),
      #(
        builder.string("jobs"),
        builder.sequence([
          builder.mapping([
            #(builder.string("name"), builder.string("test")),
            #(builder.string("run"), builder.string("gleam test")),
          ]),
        ]),
      ),
    ])
    |> yaml.from_node()

  let assert Ok(parsed) =
    document
    |> yaml.to_string()
    |> yaml.parse()

  let assert option.Some(run) =
    parsed
    |> yaml.get([node.Key("jobs"), node.Index(0), node.Key("run")])

  assert node.as_string(run) == Ok("gleam test")
}
