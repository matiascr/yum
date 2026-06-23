import birdie
import gleam/list
import gleam/result
import gleam/string
import nibble/lexer
import yaml_render
import yum/yaml/error.{type YamlError}
import yum/yaml/lexer as yum_yaml_lexer
import yum/yaml/token.{type Token}

const test_file_prefix = "lexer:comment:"

pub fn full_line_comments_test() {
  let input = "# top\none: two\n# bottom\nthree: four"

  input
  |> yum_yaml_lexer.lex()
  |> snap(input, "full_line_comments_test")
}

pub fn trailing_block_comments_test() {
  let input = "one: two # trailing\nthree: # omitted\n- item # sequence"

  input
  |> yum_yaml_lexer.lex()
  |> snap(input, "trailing_block_comments_test")
}

pub fn flow_comments_test() {
  let input = "[one, # first\ntwo, {three: four # inner\n}]"

  input
  |> yum_yaml_lexer.lex()
  |> snap(input, "flow_comments_test")
}

pub fn hash_inside_scalars_test() {
  let input =
    "plain: foo#bar\nsingle: 'foo # bar'\ndouble: \"foo # bar\"\ntrimmed: foo # bar"

  input
  |> yum_yaml_lexer.lex()
  |> snap(input, "hash_inside_scalars_test")
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
    let result = yaml_render.tokens(unwrapped)

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
