import gleam/option
import nibble.{type Parser, do}
import yum/yaml/lexer/context.{type Context}
import yum/yaml/node.{type YamlNode}
import yum/yaml/parser/block_mapping
import yum/yaml/parser/block_scalar
import yum/yaml/parser/block_sequence
import yum/yaml/parser/double_quoted
import yum/yaml/parser/flow_collection
import yum/yaml/parser/indentation
import yum/yaml/parser/scalar
import yum/yaml/parser/single_quoted
import yum/yaml/token.{type Token}

pub fn parser() -> Parser(YamlNode, Token, Context) {
  use indent <- do(nibble.optional(indentation.value_parser()))
  let indent = indent |> option.unwrap(0)

  block_collection_parser(indent)
}

fn block_sequence_parser(indent: Int) -> Parser(YamlNode, Token, Context) {
  block_sequence.parser(indent, block_node_parser)
}

fn block_mapping_parser(indent: Int) -> Parser(YamlNode, Token, Context) {
  block_mapping.parser(indent, mapping_value_parser)
}

fn block_collection_parser(indent: Int) -> Parser(YamlNode, Token, Context) {
  nibble.one_of([
    block_sequence_parser(indent),
    block_mapping_parser(indent),
  ])
}

fn compact_collection_parser(indent: Int) -> Parser(YamlNode, Token, Context) {
  block_collection_parser(indent + 2)
}

fn nested_collection_parser(
  parent_indent: Int,
) -> Parser(YamlNode, Token, Context) {
  use indent <- do(indentation.greater_than_parser(parent_indent))

  block_collection_parser(indent)
}

fn indentless_sequence_parser(
  parent_indent: Int,
) -> Parser(YamlNode, Token, Context) {
  use Nil <- do(indentation.same_amount_parser(parent_indent))
  block_sequence_parser(parent_indent)
}

fn block_node_parser(indent: Int) -> Parser(YamlNode, Token, Context) {
  nibble.one_of([
    flow_collection.parser(),
    block_scalar.parser(),
    double_quoted.parser(),
    single_quoted.parser(),
    nibble.backtrackable(compact_collection_parser(indent)),
    nested_collection_parser(indent),
    scalar.parser(),
  ])
}

fn mapping_value_parser(indent: Int) -> Parser(YamlNode, Token, Context) {
  nibble.one_of([
    flow_collection.parser(),
    block_scalar.parser(),
    double_quoted.parser(),
    single_quoted.parser(),
    nibble.backtrackable(compact_collection_parser(indent)),
    nested_collection_parser(indent),
    nibble.backtrackable(indentless_sequence_parser(indent)),
    scalar.parser(),
  ])
}
