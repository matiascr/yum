import gleam/list
import gleam/result
import yaml_ast.{type YamlAST}
import yum/yaml
import yum/yaml/diagnostic.{type Diagnostic}
import yum/yaml/error.{type YamlError}
import yum/yaml/node.{type Node}

pub type Parsed(a) {
  Parsed(value: a, diagnostics: List(Diagnostic))
}

pub fn parse_ast(input: String) -> Result(YamlAST, YamlError) {
  use document <- result.try(yaml.parse(input))
  Ok(document |> yaml.root() |> to_ast())
}

pub fn parse_ast_stream(input: String) -> Result(List(YamlAST), YamlError) {
  use documents <- result.try(yaml.parse_stream(input))
  Ok(list.map(documents, fn(document) { document |> yaml.root() |> to_ast() }))
}

pub fn parse_node(input: String) -> Result(Node, YamlError) {
  use document <- result.try(yaml.parse(input))
  Ok(yaml.root(document))
}

pub fn parse_node_with_diagnostics(
  input: String,
) -> Result(Parsed(Node), YamlError) {
  use document <- result.try(yaml.parse(input))

  let diagnostics = case yaml.resolve(document) {
    Ok(document) -> yaml.diagnostics(document)
    Error(diagnostics) -> diagnostics
  }

  Ok(Parsed(value: yaml.root(document), diagnostics:))
}

pub fn to_ast(node: Node) -> YamlAST {
  case node.kind(node) {
    node.Null -> yaml_ast.Null
    node.Bool(value) -> yaml_ast.Bool(value)
    node.Int(value) -> yaml_ast.Int(value)
    node.Float(value) -> yaml_ast.Float(value)
    node.PosInf -> yaml_ast.PosInf
    node.NegInf -> yaml_ast.NegInf
    node.Nan -> yaml_ast.Nan
    node.String(value) -> yaml_ast.String(value)
    node.Sequence(entries) -> yaml_ast.Sequence(list.map(entries, to_ast))
    node.Mapping(entries) ->
      entries
      |> list.map(fn(entry) {
        let #(key, value) = entry
        #(to_ast(key), to_ast(value))
      })
      |> yaml_ast.Mapping
  }
}
