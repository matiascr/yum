import gleam/option
import nibble.{type Parser, do}
import yum/yaml/ast.{type YamlAST}
import yum/yaml/lexer/context.{type Context}
import yum/yaml/parser/block_mapping
import yum/yaml/parser/block_sequence
import yum/yaml/parser/double_quoted
import yum/yaml/parser/flow_collection
import yum/yaml/parser/indentation
import yum/yaml/parser/scalar
import yum/yaml/parser/single_quoted
import yum/yaml/token.{type Token}

pub fn parser() -> Parser(YamlAST, Token, Context) {
  use indent <- do(nibble.optional(indentation.value_parser()))
  let indent = indent |> option.unwrap(0)
  nibble.one_of([
    block_sequence_parser(indent),
    block_mapping_parser(indent),
  ])
}

fn block_sequence_parser(indent: Int) -> Parser(YamlAST, Token, Context) {
  block_sequence.parser(indent, node_parser)
}

fn block_mapping_parser(indent: Int) -> Parser(YamlAST, Token, Context) {
  block_mapping.parser(indent, mapping_value_parser)
}

fn nested_sequence_parser(
  parent_indent: Int,
) -> Parser(YamlAST, Token, Context) {
  nibble.lazy(fn() {
    use indent <- do(indentation.value_parser())

    case indent > parent_indent {
      True -> block_sequence_parser(indent)
      False -> fail()
    }
  })
}

fn indentless_sequence_parser(
  parent_indent: Int,
) -> Parser(YamlAST, Token, Context) {
  use Nil <- do(indentation.same_parser(parent_indent))
  block_sequence_parser(parent_indent)
}

fn nested_mapping_parser(
  parent_indent: Int,
) -> Parser(YamlAST, Token, Context) {
  nibble.lazy(fn() {
    use indent <- do(indentation.value_parser())

    case indent > parent_indent {
      True -> block_mapping_parser(indent)
      False -> fail()
    }
  })
}

fn fail() -> Parser(a, Token, Context) {
  nibble.fail("Expected a block collection")
}

fn node_parser(indent: Int) -> Parser(YamlAST, Token, Context) {
  nibble.one_of([
    nested_sequence_parser(indent),
    nested_mapping_parser(indent),
    flow_collection.parser(),
    double_quoted.parser(),
    single_quoted.parser(),
    scalar.parser(),
  ])
}

fn mapping_value_parser(indent: Int) -> Parser(YamlAST, Token, Context) {
  nibble.one_of([
    nested_sequence_parser(indent),
    nested_mapping_parser(indent),
    nibble.backtrackable(indentless_sequence_parser(indent)),
    flow_collection.parser(),
    double_quoted.parser(),
    single_quoted.parser(),
    scalar.parser(),
  ])
}
