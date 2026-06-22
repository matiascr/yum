import nibble/lexer.{type Matcher}
import yum/yaml/lexer/context.{type Context}
import yum/yaml/token.{type Token}

pub fn lexer() -> Matcher(Token, Context) {
  use ctx, lexeme, lookahead <- lexer.custom()
  let assert context.SingleQuotedScalar(prev:) = ctx
  case lexeme, lookahead {
    "'", "'" -> lexer.Skip
    "''", _ -> token.SingleQuotedScalar("'") |> lexer.Keep(ctx)

    "'", _ -> lexer.Drop(prev)

    "", "'" -> lexer.Skip
    lexeme, "'" ->
      lexeme
      |> token.SingleQuotedScalar
      |> lexer.Keep(ctx)

    _, _ -> lexer.Skip
  }
}
