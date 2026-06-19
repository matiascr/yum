import gleam/option.{None, Some}
import nibble.{type Parser, do, return}
import yaml/lexer/context.{type Context}
import yaml/token.{type Token}

pub fn value_parser() -> Parser(Int, Token, Context) {
  use tok <- nibble.take_map("Expected an indentation")
  case tok {
    token.Indentation(indent) -> Some(indent)
    _ -> None
  }
}

pub fn same_parser(indent: Int) -> Parser(Nil, Token, Context) {
  use Nil <- do(nibble.token(token.Indentation(indent)))
  return(Nil)
}

pub fn block_separator_parser(indent: Int) -> Parser(Nil, Token, Context) {
  // A peer token at this indentation might belong to the parent collection.
  // Let the collection stop cleanly when the following entry parser fails.
  same_parser(indent)
  |> nibble.backtrackable
}
