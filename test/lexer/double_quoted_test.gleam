import birdie
import gleam/list
import gleam/result
import gleam/string
import nibble/lexer
import yaml/error.{type YamlError}
import yaml/lexer as yaml_lexer
import yaml/token.{type Token}

const test_file_prefix = "lexer:double_quoted:"

pub fn empty_double_quoted_test() {
  let input = "\"\""

  input
  |> yaml_lexer.lex()
  |> snap(input, "empty_double_quoted_test")
}

pub fn simple_double_quoted_test() {
  let input = "\"hello world\""

  input
  |> yaml_lexer.lex()
  |> snap(input, "simple_double_quoted_test")
}

pub fn indicator_characters_double_quoted_test() {
  let input = "\"- ? : , [ ] { } # & * ! | > ' % @ `\""

  input
  |> yaml_lexer.lex()
  |> snap(input, "indicator_characters_double_quoted_test")
}

pub fn escaped_quotes_and_slashes_double_quoted_test() {
  let input = "\"\\\" \\/ \\\\\""

  input
  |> yaml_lexer.lex()
  |> snap(input, "escaped_quotes_and_slashes_double_quoted_test")
}

pub fn escaped_control_characters_double_quoted_test() {
  let input = "\"\\0 \\a \\b \\t \\n \\v \\f \\r \\e\""

  input
  |> yaml_lexer.lex()
  |> snap(input, "escaped_control_characters_double_quoted_test")
}

pub fn escaped_unicode_characters_double_quoted_test() {
  let input = "\"\\  \\_ \\N \\L \\P \\x41 \\u0042 \\U00000043\""

  input
  |> yaml_lexer.lex()
  |> snap(input, "escaped_unicode_characters_double_quoted_test")
}

pub fn folded_line_break_double_quoted_test() {
  let input = "\"folded \nto a space\""

  input
  |> yaml_lexer.lex()
  |> snap(input, "folded_line_break_double_quoted_test")
}

pub fn empty_line_fold_double_quoted_test() {
  let input = "\"folded\n\nas a line feed\""

  input
  |> yaml_lexer.lex()
  |> snap(input, "empty_line_fold_double_quoted_test")
}

pub fn escaped_line_break_double_quoted_test() {
  let input = "\"folded \\\n  together\""

  input
  |> yaml_lexer.lex()
  |> snap(input, "escaped_line_break_double_quoted_test")
}

pub fn preserved_space_before_escaped_break_test() {
  let input = "\"keep  \\\n  next\""

  input
  |> yaml_lexer.lex()
  |> snap(input, "preserved_space_before_escaped_break_test")
}

pub fn escaped_space_after_escaped_break_test() {
  let input = "\"keep\\\n \\ space\""

  input
  |> yaml_lexer.lex()
  |> snap(input, "escaped_space_after_escaped_break_test")
}

pub fn leading_trailing_multiline_whitespace_test() {
  let input = "\"  first\n second \n\""

  input
  |> yaml_lexer.lex()
  |> snap(input, "leading_trailing_multiline_whitespace_test")
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
      "Input:\n\n```yaml\n"
      <> input
      <> "\n```\n\n"
      <> string.repeat("-", 71)
      <> "\n\n```gleam\n"
      <> result
      <> "\n\n```"

    snap_contents
    |> birdie.snap(test_file_prefix <> title)
    |> Ok
  })
}
