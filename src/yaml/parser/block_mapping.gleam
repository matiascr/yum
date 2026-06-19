import nibble.{type Parser}
import yaml.{type Yaml}
import yaml/lexer/context.{type Context}
import yaml/parser/block_collection
import yaml/token.{type Token}

pub fn parser() -> Parser(Yaml, Token, Context) {
  block_collection.mapping_parser()
}
