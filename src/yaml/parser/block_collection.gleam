import gleam/option.{None, Some}
import nibble.{type Parser, do, return}
import yaml.{type Yaml}
import yaml/lexer/context.{type Context}
import yaml/parser/double_quoted
import yaml/parser/flow_mapping
import yaml/parser/flow_sequence
import yaml/parser/scalar
import yaml/parser/single_quoted
import yaml/token.{type Token}

pub fn sequence_parser() -> Parser(Yaml, Token, Context) {
  use indent <- do(nibble.optional(indentation_value_parser()))
  indent
  |> option.unwrap(0)
  |> block_sequence_parser()
}

pub fn mapping_parser() -> Parser(Yaml, Token, Context) {
  use indent <- do(nibble.optional(indentation_value_parser()))
  indent
  |> option.unwrap(0)
  |> block_mapping_parser()
}

fn block_sequence_parser(indent: Int) -> Parser(Yaml, Token, Context) {
  use entries <- do(nibble.sequence(
    sequence_entry_parser(indent),
    separator: block_separator_parser(indent),
  ))

  case entries {
    [] -> fail()
    [_, ..] ->
      entries
      |> yaml.Sequence
      |> return
  }
}

fn sequence_entry_parser(indent: Int) -> Parser(Yaml, Token, Context) {
  use _ <- do(nibble.token(token.Hyphen))
  use value <- do(nibble.optional(node_parser(indent)))

  value
  |> option.unwrap(yaml.Null)
  |> return
}

fn block_mapping_parser(indent: Int) -> Parser(Yaml, Token, Context) {
  use entries <- do(nibble.sequence(
    mapping_entry_parser(indent),
    separator: block_separator_parser(indent),
  ))

  case entries {
    [] -> fail()
    [_, ..] ->
      entries
      |> yaml.Mapping
      |> return
  }
}

fn mapping_entry_parser(indent: Int) -> Parser(#(Yaml, Yaml), Token, Context) {
  use key <- do(mapping_key_parser())
  use value <- do(nibble.optional(mapping_value_parser(indent)))

  value
  |> option.unwrap(yaml.Null)
  |> pair_with(key)
  |> return
}

fn mapping_key_parser() -> Parser(Yaml, Token, Context) {
  use tok <- nibble.take_map("Expected a block mapping key")
  case tok {
    token.MappingKey(value:) -> scalar.parse(value)
    _ -> None
  }
}

fn pair_with(value: Yaml, key: Yaml) -> #(Yaml, Yaml) {
  #(key, value)
}

fn same_indentation_parser(indent: Int) -> Parser(Nil, Token, Context) {
  use Nil <- do(nibble.token(token.Indentation(indent)))
  return(Nil)
}

fn block_separator_parser(indent: Int) -> Parser(Nil, Token, Context) {
  // A peer token at this indentation might belong to the parent collection.
  // Let the collection stop cleanly when the following entry parser fails.
  same_indentation_parser(indent)
  |> nibble.backtrackable
}

fn indentation_value_parser() -> Parser(Int, Token, Context) {
  use tok <- nibble.take_map("Expected an indentation")
  case tok {
    token.Indentation(indent) -> Some(indent)
    _ -> None
  }
}

fn nested_sequence_parser(parent_indent: Int) -> Parser(Yaml, Token, Context) {
  use indent <- do(indentation_value_parser())

  case indent > parent_indent {
    True -> block_sequence_parser(indent)
    False -> fail()
  }
}

fn indentless_sequence_parser(
  parent_indent: Int,
) -> Parser(Yaml, Token, Context) {
  use Nil <- do(same_indentation_parser(parent_indent))

  block_sequence_parser(parent_indent)
}

fn nested_mapping_parser(parent_indent: Int) -> Parser(Yaml, Token, Context) {
  use indent <- do(indentation_value_parser())

  case indent > parent_indent {
    True -> block_mapping_parser(indent)
    False -> fail()
  }
}

fn fail() -> Parser(a, Token, Context) {
  nibble.fail("Expected a block collection")
}

fn node_parser(indent: Int) -> Parser(Yaml, Token, Context) {
  nibble.one_of([
    nibble.lazy(fn() { nested_sequence_parser(indent) }),
    nibble.lazy(fn() { nested_mapping_parser(indent) }),
    nibble.lazy(flow_sequence.parser),
    nibble.lazy(flow_mapping.parser),
    double_quoted.parser(),
    single_quoted.parser(),
    scalar.parser(),
  ])
}

fn mapping_value_parser(indent: Int) -> Parser(Yaml, Token, Context) {
  nibble.one_of([
    nibble.lazy(fn() { nested_sequence_parser(indent) }),
    nibble.lazy(fn() { nested_mapping_parser(indent) }),
    nibble.lazy(fn() { indentless_sequence_parser(indent) })
      |> nibble.backtrackable,
    nibble.lazy(flow_sequence.parser),
    nibble.lazy(flow_mapping.parser),
    double_quoted.parser(),
    single_quoted.parser(),
    scalar.parser(),
  ])
}
