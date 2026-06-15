import birdie
import gleam/list
import gleam/result
import gleam/string
import nibble/lexer
import yaml/error.{type YamlError}
import yaml/lexer as yaml_lexer
import yaml/token.{type Token}

const test_file_prefix = "lexer:primitives:"

pub fn canonical_integer_primitives_test() {
  let input = "12345"

  input
  |> yaml_lexer.lex()
  |> snap(input, "implement canonical_integer_primitives_test")
}

pub fn decimal_integer_primitives_test() {
  let input = "+12345"

  input
  |> yaml_lexer.lex()
  |> snap(input, "implement decimal_integer_primitives_test")
}

pub fn octal_integer_primitives_test() {
  let input = "0o14"

  input
  |> yaml_lexer.lex()
  |> snap(input, "implement octal_integer_primitives_test")
}

pub fn hexadecimal_integer_primitives_test() {
  let input = "0xC"

  input
  |> yaml_lexer.lex()
  |> snap(input, "implement hexadecimal_integer_primitives_test")
}

pub fn canonical_float_primitives_test() {
  let input = "1.23015e+3"

  input
  |> yaml_lexer.lex()
  |> snap(input, "implement canonical_float_primitives_test")
}

pub fn exponential_float_primitives_test() {
  let input = "12.3015e+02"

  input
  |> yaml_lexer.lex()
  |> snap(input, "implement exponential_float_primitives_test")
}

pub fn fixed_float_primitives_test() {
  let input = "1230.15"

  input
  |> yaml_lexer.lex()
  |> snap(input, "implement fixed_float_primitives_test")
}

pub fn negative_infinity_float_primitives_test() {
  let input = "-.inf"

  input
  |> yaml_lexer.lex()
  |> snap(input, "implement negative_infinity_float_primitives_test")
}

pub fn not_a_number_float_primitives_test() {
  let input = ".nan"

  input
  |> yaml_lexer.lex()
  |> snap(input, "implement not_a_number_float_primitives_test")
}

pub fn null_lowercase_primitives_test() {
  let input = "null"

  input
  |> yaml_lexer.lex()
  |> snap(input, "implement null_lowercase_primitives_test")
}

pub fn true_lowercase_primitives_test() {
  let input = "true"

  input
  |> yaml_lexer.lex()
  |> snap(input, "implement true_lowercase_primitives_test")
}

pub fn false_lowercase_primitives_test() {
  let input = "false"

  input
  |> yaml_lexer.lex()
  |> snap(input, "implement false_lowercase_primitives_test")
}

fn unwrap_token(result: Result(List(lexer.Token(Token)), YamlError)) {
  use l <- result.try(result)
  l
  |> list.map(fn(token) { token.value })
  |> Ok
}

fn snap(
  tokens: Result(List(lexer.Token(Token)), YamlError),
  input: String,
  title: String,
) {
  assert result.is_ok({
    use unwrapped <- result.try(unwrap_token(tokens))
    let result = string.inspect(unwrapped)

    let snap_contents =
      "Input:\n\n"
      <> input
      <> "\n\n"
      <> string.repeat("-", 71)
      <> "\n\n```gleam\n"
      <> result
      <> "\n\n```"

    snap_contents
    |> birdie.snap(test_file_prefix <> title)
    |> Ok
  })
}
