import birdie
import gleam/list
import gleam/result
import gleam/string
import nibble/lexer
import yum/yaml/error.{type YamlError}
import yum/yaml/lexer as yum_yaml_lexer
import yum/yaml/token.{type Token}

const test_file_prefix = "lexer:primitives:"

pub fn canonical_integer_primitives_test() {
  let input = "12345"

  input
  |> yum_yaml_lexer.lex()
  |> snap(input, "canonical_integer_primitives_test")
}

pub fn decimal_integer_primitives_test() {
  let input = "+12345"

  input
  |> yum_yaml_lexer.lex()
  |> snap(input, "decimal_integer_primitives_test")
}

pub fn octal_integer_primitives_test() {
  let input = "0o14"

  input
  |> yum_yaml_lexer.lex()
  |> snap(input, "octal_integer_primitives_test")
}

pub fn hexadecimal_integer_primitives_test() {
  let input = "0xC"

  input
  |> yum_yaml_lexer.lex()
  |> snap(input, "hexadecimal_integer_primitives_test")
}

pub fn canonical_float_primitives_test() {
  let input = "1.23015e+3"

  input
  |> yum_yaml_lexer.lex()
  |> snap(input, "canonical_float_primitives_test")
}

pub fn exponential_float_primitives_test() {
  let input = "12.3015e+02"

  input
  |> yum_yaml_lexer.lex()
  |> snap(input, "exponential_float_primitives_test")
}

pub fn fixed_float_primitives_test() {
  let input = "1230.15"

  input
  |> yum_yaml_lexer.lex()
  |> snap(input, "fixed_float_primitives_test")
}

pub fn negative_infinity_float_primitives_test() {
  let input = "-.inf"

  input
  |> yum_yaml_lexer.lex()
  |> snap(input, "negative_infinity_float_primitives_test")
}

pub fn not_a_number_float_primitives_test() {
  let input = ".nan"

  input
  |> yum_yaml_lexer.lex()
  |> snap(input, "not_a_number_float_primitives_test")
}

pub fn null_lowercase_primitives_test() {
  let input = "null"

  input
  |> yum_yaml_lexer.lex()
  |> snap(input, "null_lowercase_primitives_test")
}

pub fn true_lowercase_primitives_test() {
  let input = "true"

  input
  |> yum_yaml_lexer.lex()
  |> snap(input, "true_lowercase_primitives_test")
}

pub fn false_lowercase_primitives_test() {
  let input = "false"

  input
  |> yum_yaml_lexer.lex()
  |> snap(input, "false_lowercase_primitives_test")
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
