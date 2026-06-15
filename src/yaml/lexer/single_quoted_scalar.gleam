import nibble/lexer.{type Matcher}
import yaml/lexer/context.{type Context}
import yaml/token.{type Token}

pub fn lexer() -> Matcher(Token, Context) {
  use ctx, lexeme, lookahead <- lexer.custom()
  todo as "implement single-quoted scalar lexer"
}
