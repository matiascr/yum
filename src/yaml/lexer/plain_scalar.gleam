import gleam/string
import nibble/lexer.{type Matcher}
import yaml/lexer/context.{type Context}
import yaml/token.{type Token}

pub fn lexer() -> Matcher(Token, Context) {
  use ctx, lexeme, lookahead <- lexer.custom()
  let assert context.FlowStyle(prev:) = ctx
  case lexeme, lookahead {
    " ", _ | "\t", _ | "\r", _ -> lexer.Drop(ctx)

    "-", " " | "-", "\n" | "-", "" -> token.Hyphen |> lexer.Keep(ctx)
    "{", _ -> token.OpenMapping |> lexer.Keep(context.FlowMapping(ctx))
    "[", _ -> token.OpenSequence |> lexer.Keep(context.FlowSequence(ctx))
    "\"", _ -> token.DoubleQuote |> lexer.Keep(context.DoubleQuotedScalar(ctx))
    "'", _ -> token.SingleQuote |> lexer.Keep(context.SingleQuotedScalar(ctx))

    _, "#" ->
      case ends_with_whitespace(lexeme) {
        True -> keep_plain_scalar(lexeme)(prev)
        False -> lexer.Skip
      }
    _, " " | _, "\t" | _, "\r" ->
      case string.ends_with(lexeme, ":") {
        True -> keep_mapping_key(lexeme)(ctx)
        False -> lexer.Skip
      }
    _, "\n" ->
      case string.ends_with(lexeme, ":") {
        True -> keep_mapping_key(lexeme)(ctx)
        False -> keep_plain_scalar(lexeme)(prev)
      }
    _, "" ->
      case string.ends_with(lexeme, ":") {
        True -> keep_mapping_key(lexeme)(ctx)
        False -> keep_plain_scalar(lexeme)(prev)
      }
    _, _ -> lexer.Skip
  }
}

fn ends_with_whitespace(s: String) -> Bool {
  string.ends_with(s, " ")
  || string.ends_with(s, "\t")
  || string.ends_with(s, "\r")
  || string.ends_with(s, "\n")
}

fn keep_mapping_key(lexeme: String) {
  let key =
    lexeme
    |> string.drop_end(1)
    |> string.trim_end()
    |> token.MappingKey

  lexer.Keep(key, _)
}

fn keep_plain_scalar(lexeme: String) {
  let key =
    lexeme
    // Leading whitespace is already being dropped in the lexer
    |> string.trim_end()
    |> token.PlainScalar

  lexer.Keep(key, _)
}
