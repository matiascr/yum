import gleam/result
import yaml.{type Yaml}
import yaml/error.{type YamlError}
import yaml/lexer
import yaml/parser

pub fn parse(input: String) -> Result(Yaml, YamlError) {
  use input <- result.try(normalize_whitespace(input))
  use input <- result.try(normalize_indents(input))

  use tokens <- result.try(lexer.lex(input))
  use parsed <- result.try(parser.parse(tokens))
  Ok(parsed)
}

fn normalize_indents(input: String) -> Result(String, YamlError) {
  todo
}

fn normalize_whitespace(input: String) -> Result(String, YamlError) {
  todo
}
