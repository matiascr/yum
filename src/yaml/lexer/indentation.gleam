import nibble/lexer.{type Matcher}
import yaml/lexer/context.{type Context}
import yaml/token.{type Token}

pub fn lexer() -> Matcher(Token, Context) {
  use _ctx, _lexeme, _lookahead <- lexer.custom()
  todo as "implement indentation lexer"
}
