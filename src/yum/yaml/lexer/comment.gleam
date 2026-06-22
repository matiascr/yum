import gleam/string
import nibble/lexer.{type Matcher}
import yum/yaml/lexer/context.{type Context}
import yum/yaml/token.{type Token}

pub fn lexer() -> Matcher(Token, Context) {
  use ctx, lexeme, lookahead <- lexer.custom()
  case lexeme, lookahead {
    "#", "\n" | "#", "" -> lexer.Drop(ctx)
    "#" <> _, "\n" | "#" <> _, "" -> lexer.Drop(ctx)
    "#", _ | "#" <> _, _ -> lexer.Skip

    _, "#" ->
      case string.trim(lexeme) == "" {
        True -> lexer.Drop(ctx)
        False -> lexer.NoMatch
      }

    _, _ -> lexer.NoMatch
  }
}
