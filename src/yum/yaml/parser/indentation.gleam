import gleam/option.{None, Some}
import nibble.{type Parser, do, return}
import yum/yaml/lexer/context.{type Context}
import yum/yaml/token.{type Token}

/// Parses an indentation and returns its amount.
pub fn value_parser() -> Parser(Int, Token, Context) {
  use tok <- nibble.take_map("Expected an indentation")
  case tok {
    token.Indentation(indent) -> Some(indent)
    _ -> None
  }
}

/// Parses an indentation of the same amount as the one provided.
pub fn same_amount_parser(indent: Int) -> Parser(Nil, Token, Context) {
  nibble.token(token.Indentation(indent))
}

/// Parses an indentation that starts a nested block collection.
pub fn greater_than_parser(parent_indent: Int) -> Parser(Int, Token, Context) {
  use indent <- do(value_parser())
  use Nil <- do(nibble.guard(
    indent > parent_indent,
    "Expected a deeper indentation",
  ))

  return(indent)
}

pub fn block_separator_parser(indent: Int) -> Parser(Nil, Token, Context) {
  // A peer token at this indentation might belong to the parent collection.
  // Let the collection stop cleanly when the following entry parser fails.
  same_amount_parser(indent)
  |> nibble.backtrackable
}
