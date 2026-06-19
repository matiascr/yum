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

    _, "\n" -> keep_plain_scalar(lexeme, prev)
    _, "" -> keep_plain_scalar(lexeme, prev)
    _, _ -> lexer.Skip
  }
}

fn keep_plain_scalar(lexeme: String, next: Context) {
  lexeme
  // Leading whitespace is already being dropped in the lexer
  |> string.trim_end()
  |> token.PlainScalar
  |> lexer.Keep(next)
}
