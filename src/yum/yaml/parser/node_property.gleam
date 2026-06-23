import gleam/option.{None, Some}
import nibble.{type Parser, do, return}
import yum/yaml/lexer/context.{type Context}
import yum/yaml/node.{type Node}
import yum/yaml/parser/span
import yum/yaml/token.{type Token}

pub fn parser(
  node_parser: Parser(Node, Token, Context),
) -> Parser(Node, Token, Context) {
  nibble.one_of([
    alias_parser(),
    property_parser(node_parser),
  ])
}

fn property_parser(
  node_parser: Parser(Node, Token, Context),
) -> Parser(Node, Token, Context) {
  use properties <- do(nibble.many(property_token_parser()))
  use value <- do(node_parser)

  properties
  |> apply_properties(value)
  |> return
}

type Property {
  Anchor(String)
  Tag(String)
}

fn property_token_parser() -> Parser(Property, Token, Context) {
  nibble.take_map("Expected a node property", fn(tok) {
    case tok {
      token.Anchor(value:) -> Some(Anchor(value))
      token.Tag(value:) -> Some(Tag(value))
      _ -> None
    }
  })
}

fn apply_properties(properties: List(Property), value: Node) -> Node {
  case properties {
    [] -> value
    [property, ..rest] -> {
      let value = apply_property(value, property)
      apply_properties(rest, value)
    }
  }
}

fn apply_property(value: Node, property: Property) -> Node {
  case property {
    Anchor(anchor) -> node.with_anchor(value, anchor)
    Tag(tag) -> node.with_tag(value, tag)
  }
}

fn alias_parser() -> Parser(Node, Token, Context) {
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
