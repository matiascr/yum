import gleam/string
import nibble/lexer.{type Matcher}
import yaml/lexer/context.{type Context}
import yaml/token.{type Token}

pub fn lexer() -> Matcher(Token, Context) {
  use ctx, lexeme, lookahead <- lexer.custom()
  case lexeme {
    "{" -> token.OpenMapping |> lexer.Keep(context.FlowMapping(ctx))
    "[" -> token.OpenSequence |> lexer.Keep(context.FlowSequence(ctx))
    "\"" -> token.DoubleQuote |> lexer.Keep(context.DoubleQuotedScalar(ctx))
    "'" -> token.SingleQuote |> lexer.Keep(context.SingleQuotedScalar(ctx))

    _ ->
      case string.is_empty(lookahead) {
        True -> lexer.Keep(token.PlainScalar(lexeme), ctx)
        False -> lexer.Skip
      }
  }
}
