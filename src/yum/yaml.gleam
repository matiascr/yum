//// YAML parsing.
////
//// This is the main public module for parsing YAML documents:
////
//// ```gleam
//// import yum/yaml
////
//// yaml.parse("name: yum")
//// ```
////
//// Use [`parse`](#parse) when you want a single YAML document value, including
//// document-level metadata such as directives. Use [`parse_stream`](#parse_stream) for
//// YAML streams containing zero or more explicit documents. Use [`parse_ast`](#parse_ast)
//// and [`parse_ast_stream`](#parse_ast_stream) when you only need parsed node trees.
////

import gleam/bool
import gleam/int
import gleam/list
import gleam/result
import gleam/string
import yum/yaml/ast.{type Yaml, type YamlAST}
import yum/yaml/error.{type YamlError}
import yum/yaml/lexer
import yum/yaml/parser

/// Parses a YAML file into a YAML document.
///
/// Follows the [YAML 1.2 specification](https://yaml.org/spec/1.2.2/)
///
pub fn parse(input: String) -> Result(Yaml, YamlError) {
  input
  |> parse_ast()
  |> result.map(ast.to_yaml)
}

/// Parses a YAML stream into a list of YAML documents.
///
pub fn parse_stream(input: String) -> Result(List(Yaml), YamlError) {
  input
  |> parse_ast_stream()
  |> result.map(list.map(_, ast.to_yaml))
}

/// Parses a YAML file into the AST node for its document contents.
///
pub fn parse_ast(input: String) -> Result(YamlAST, YamlError) {
  use documents <- result.try(parse_ast_stream(input))

  case documents {
    [document] -> Ok(document)
    [_, _, ..] -> Error(error.MultipleDocuments)
    [] -> Error(error.UnexpectedEndOfInput)
  }
}

/// Parses a YAML stream into the AST nodes for each document's contents.
///
pub fn parse_ast_stream(input: String) -> Result(List(YamlAST), YamlError) {
  use input <- result.try(normalize_whitespace(input, 0))
  use input <- result.try(normalize_indents(input))

  use tokens <- result.try(lexer.lex(input))
  use parsed <- result.try(parser.parse_stream(tokens))
  Ok(parsed)
}

/// Normalizes whitespace in the YAML file.
/// By default, turns every un-escaped tab (`\t`) into the given amount of
/// whitespaces.
///
fn normalize_whitespace(
  input: String,
  tab_equivalent: Int,
) -> Result(String, YamlError) {
  use <- bool.guard(when: tab_equivalent == 0, return: Ok(input))
  input
  |> string.replace(each: "\t", with: string.repeat(" ", tab_equivalent))
  |> Ok
}

/// Normalizes the indentation of the YAML file.
/// If all lines have <X leading whitespace, all lines will be trimmed X spaces
/// going forward.
///
fn normalize_indents(input: String) -> Result(String, YamlError) {
  let lines = string.split(input, "\n")
  use x <- result.try(find_min_indent(lines))
  let min_indent = int.absolute_value(x)

  lines
  |> list.map(string.drop_start(_, min_indent))
  |> string.join("\n")
  |> Ok
}

fn find_min_indent(lines: List(String)) -> Result(Int, YamlError) {
  lines
  |> list.map(count_indents)
  |> list.map(int.negate)
  |> list.max(int.compare)
  |> result.replace_error(error.IndentNormalizationError)
}

fn count_indents(input: String) -> Int {
  case input {
    " " <> rest -> 1 + count_indents(rest)
    _ -> 0
  }
}
