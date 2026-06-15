import nibble/lexer
import yaml/error.{type YamlError}
import yaml/token.{type Token}

pub fn lex(input: String) -> Result(List(lexer.Token(Token)), YamlError) {
  todo
}
