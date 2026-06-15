import gleam/int
import gleam/list
import gleam/result
import gleam/string
import yaml.{type Yaml}
import yaml/error.{type YamlError}
import yaml/lexer
import yaml/parser

/// Parses a YAML file into a Gleam object equivalent.
///
/// Follows the [YAML 1.2 specification](https://yaml.org/spec/1.2.2/)
///
pub fn parse(input: String) -> Result(Yaml, YamlError) {
  use input <- result.try(normalize_whitespace(input, 2))
  use input <- result.try(normalize_indents(input))

  use tokens <- result.try(lexer.lex(input))
  use parsed <- result.try(parser.parse(tokens))
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
