import birdie
import gleam/result
import gleam/string
import yum

const test_file_prefix = "parser:comment:"

pub fn full_line_comments_test() {
  let input = "# top\none: two\n# bottom\nthree: four"

  input
  |> yum.parse()
  |> snap(input, "full_line_comments_test")
}

pub fn trailing_block_comments_test() {
  let input = "one: two # trailing\nthree: # omitted\nfour: item # scalar"

  input
  |> yum.parse()
  |> snap(input, "trailing_block_comments_test")
}

pub fn flow_comments_test() {
  let input = "[one, # first\ntwo, {three: four # inner\n}]"

  input
  |> yum.parse()
  |> snap(input, "flow_comments_test")
}

pub fn hash_inside_scalars_test() {
  let input =
    "plain: foo#bar\nsingle: 'foo # bar'\ndouble: \"foo # bar\"\ntrimmed: foo # bar"

  input
  |> yum.parse()
  |> snap(input, "hash_inside_scalars_test")
}

fn snap(parsed: _, input: String, title: String) {
  assert result.is_ok({
    use yaml <- result.try(parsed)
    let result = string.inspect(yaml)

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
