import nibble.{type Parser}
import yaml.{type Yaml}
import yaml/lexer/context.{type Context}
import yaml/parser/flow_collection
import yaml/token.{type Token}

pub fn parser() -> Parser(Yaml, Token, Context) {
  flow_collection.mapping_parser()
}
