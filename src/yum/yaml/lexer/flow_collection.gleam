import gleam/list
import gleam/string
import nibble/lexer
import yum/yaml/lexer/context.{type Context}
import yum/yaml/token

pub fn ends_with_whitespace(s: String) -> Bool {
  string.ends_with(s, " ")
  || string.ends_with(s, "\t")
  || string.ends_with(s, "\r")
  || string.ends_with(s, "\n")
}

pub fn keep_plain_scalar(lexeme: String, ctx: Context) {
  let scalar =
    lexeme
    |> string.split("\n")
    |> fold_plain_lines(starting_with: [], prior_empty_lines: 0)
    |> string.concat()

  case string.ends_with(scalar, ":") {
    True ->
      scalar
      |> string.drop_end(1)
      |> string.trim_end()
      |> token.MappingKey
      |> lexer.Keep(ctx)
    False ->
      scalar
      |> token.PlainScalar
      |> lexer.Keep(ctx)
  }
}

fn fold_plain_lines(
  lines: List(String),
  starting_with parts: List(String),
  prior_empty_lines empty_lines: Int,
) -> List(String) {
  case lines {
    [] -> list.reverse(parts)
    [line, ..rest] -> {
      let line = string.trim(line)
      case string.is_empty(line), parts {
        True, _ -> fold_plain_lines(rest, parts, empty_lines + 1)
        False, [] -> fold_plain_lines(rest, [line], 0)
        False, [_, ..] -> {
          let separator = case empty_lines > 0 {
            True -> string.repeat("\n", empty_lines)
            False -> " "
          }

          fold_plain_lines(rest, [line, separator, ..parts], 0)
        }
      }
    }
  }
}
