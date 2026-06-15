import nibble/lexer
import yaml.{type Yaml}
import yaml/error.{type YamlError}
import yaml/token.{type Token}

pub fn parse(tokens: List(lexer.Token(Token))) -> Result(Yaml, YamlError) {
  todo
}
