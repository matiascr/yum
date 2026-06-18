import gleam/list
import gleam/string
import nibble/lexer.{type Matcher}
import yaml/lexer/context.{type Context}
import yaml/token.{type Token}

pub fn lexer() -> Matcher(Token, Context) {
  use ctx, lexeme, lookahead <- lexer.custom()
  let assert context.FlowSequence(prev:) = ctx
  case lexeme, lookahead {
    " ", _ | "\t", _ | "\r", _ | "\n", _ -> lexer.Drop(ctx)

    "]", _ -> token.CloseSequence |> lexer.Keep(prev)
    ",", _ -> token.Comma |> lexer.Keep(ctx)
    "[", _ -> token.OpenSequence |> lexer.Keep(context.FlowSequence(ctx))
    "{", _ -> token.OpenMapping |> lexer.Keep(context.FlowMapping(ctx))
    "\"", _ -> token.DoubleQuote |> lexer.Keep(context.DoubleQuotedScalar(ctx))
    "'", _ -> token.SingleQuote |> lexer.Keep(context.SingleQuotedScalar(ctx))

    _, "]" | _, "," | _, "[" | _, "{" | _, "\"" | _, "'" ->
      keep_plain_scalar(lexeme, ctx)
    _, "" -> keep_plain_scalar(lexeme, ctx)
    _, _ -> lexer.Skip
  }
}

fn keep_plain_scalar(lexeme: String, ctx: Context) {
  lexeme
  |> string.trim_end()
  |> fold_plain_scalar()
  |> token.PlainScalar
  |> lexer.Keep(ctx)
}

fn fold_plain_scalar(scalar: String) -> String {
  scalar
  |> string.split("\n")
  |> fold_plain_lines([], 0)
  |> string.concat()
}

fn fold_plain_lines(
  lines: List(String),
  parts: List(String),
  empty_lines: Int,
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
