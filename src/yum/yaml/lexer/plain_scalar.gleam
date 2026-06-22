import gleam/string
import nibble/lexer.{type Matcher}
import yum/yaml/lexer/context.{type Context}
import yum/yaml/token.{type Token}

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
    "?", " " | "?", "\t" | "?", "\r" | "?", "\n" | "?", "" ->
      token.QuestionMark |> lexer.Keep(ctx)
    ":", " " | ":", "\t" | ":", "\r" | ":", "\n" | ":", "" ->
      token.Colon |> lexer.Keep(ctx)

    _, "#" ->
      case ends_with_whitespace(lexeme) {
        True -> plain_scalar(lexeme) |> lexer.Keep(prev)
        False -> lexer.Skip
      }
    _, " " | _, "\t" | _, "\r" ->
      case string.ends_with(lexeme, ":") {
        True -> mapping_key(lexeme) |> lexer.Keep(ctx)
        False -> lexer.Skip
      }
    _, "\n" ->
      case string.ends_with(lexeme, ":") {
        True -> mapping_key(lexeme) |> lexer.Keep(ctx)
        False -> plain_scalar(lexeme) |> lexer.Keep(prev)
      }
    _, "" ->
      case string.ends_with(lexeme, ":") {
        True -> mapping_key(lexeme) |> lexer.Keep(ctx)
        False -> plain_scalar(lexeme) |> lexer.Keep(prev)
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

fn mapping_key(lexeme: String) {
  lexeme
  |> string.drop_end(1)
  |> string.trim_end()
  |> token.MappingKey
}

fn plain_scalar(lexeme: String) {
  lexeme
  // Leading whitespace is already being dropped in the lexer
  |> string.trim_end()
  |> token.PlainScalar
}
