import birdie
import gleam/result
import gleam/string
import yum

const test_file_prefix = "parser:primitives:"

pub fn canonical_integer_primitives_test() {
  let input = "12345"

  input
  |> yum.parse()
  |> snap(input, "canonical_integer_primitives_test")
}

pub fn decimal_integer_primitives_test() {
  let input = "+12345"

  input
  |> yum.parse()
  |> snap(input, "decimal_integer_primitives_test")
}

pub fn octal_integer_primitives_test() {
  let input = "0o14"

  input
  |> yum.parse()
  |> snap(input, "octal_integer_primitives_test")
}

pub fn hexadecimal_integer_primitives_test() {
  let input = "0xC"

  input
  |> yum.parse()
  |> snap(input, "hexadecimal_integer_primitives_test")
}

pub fn canonical_float_primitives_test() {
  let input = "1.23015e+3"

  input
  |> yum.parse()
  |> snap(input, "canonical_float_primitives_test")
}

pub fn exponential_float_primitives_test() {
  let input = "12.3015e+02"

  input
  |> yum.parse()
  |> snap(input, "exponential_float_primitives_test")
}

pub fn fixed_float_primitives_test() {
  let input = "1230.15"

  input
  |> yum.parse()
  |> snap(input, "fixed_float_primitives_test")
}

pub fn negative_infinity_float_primitives_test() {
  let input = "-.inf"

  input
  |> yum.parse()
  |> snap(input, "negative_infinity_float_primitives_test")
}

pub fn not_a_number_float_primitives_test() {
  let input = ".nan"

  input
  |> yum.parse()
  |> snap(input, "not_a_number_float_primitives_test")
}

pub fn null_lowercase_primitives_test() {
  let input = "null"

  input
  |> yum.parse()
  |> snap(input, "null_lowercase_primitives_test")
}

pub fn true_lowercase_primitives_test() {
  let input = "true"

  input
  |> yum.parse()
  |> snap(input, "true_lowercase_primitives_test")
}

pub fn false_lowercase_primitives_test() {
  let input = "false"

  input
  |> yum.parse()
  |> snap(input, "false_lowercase_primitives_test")
}

fn snap(parsed: _, input: String, title: String) {
  assert result.is_ok({
    use yaml <- result.try(parsed)
    let result = string.inspect(yaml)

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
