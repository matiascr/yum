import gleam/list
import gleam/option.{None, Some}
import nibble.{type Parser, do, return}
import yum/yaml/lexer/context.{type Context}
import yum/yaml/node.{type YamlNode}
import yum/yaml/parser/span
import yum/yaml/token.{type Token}

pub fn parser(
  node_parser: Parser(YamlNode, Token, Context),
) -> Parser(YamlNode, Token, Context) {
  nibble.one_of([
    alias_parser(),
    property_parser(node_parser),
  ])
}

fn property_parser(
  node_parser: Parser(YamlNode, Token, Context),
) -> Parser(YamlNode, Token, Context) {
  use anchors <- do(nibble.many(anchor_parser()))
  use value <- do(node_parser)

  anchors
  |> list.fold(value, fn(value, anchor) { node.with_anchor(value, anchor) })
  |> return
}

fn anchor_parser() -> Parser(String, Token, Context) {
  nibble.take_map("Expected an anchor", fn(tok) {
    case tok {
      token.Anchor(value:) -> Some(value)
      _ -> None
    }
  })
}

fn alias_parser() -> Parser(YamlNode, Token, Context) {
  use alias <- do(
    nibble.take_map("Expected an alias", fn(tok) {
      case tok {
        token.Alias(value:) -> Some(value)
        _ -> None
      }
    }),
  )
  use token_span <- do(nibble.span())

  node.new(node.Null, span: span.from_lexer(token_span), style: node.Synthetic)
  |> node.with_alias(alias)
  |> return
}
