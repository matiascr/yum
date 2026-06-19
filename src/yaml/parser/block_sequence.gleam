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

pub fn parser() -> Parser(Yaml, Token, Context) {
  use indent <- do(nibble.optional(indentation_value_parser()))
  indent
  |> option.unwrap(0)
  |> sequence_parser()
}

fn sequence_parser(indent: Int) -> Parser(Yaml, Token, Context) {
  use entries <- do(nibble.sequence(
    entry_parser(indent),
    separator: same_indentation_parser(indent),
  ))

  case entries {
    [] -> fail()
    [_, ..] ->
      entries
      |> yaml.Sequence
      |> return
  }
}

fn entry_parser(indent: Int) -> Parser(Yaml, Token, Context) {
  use _ <- do(nibble.token(token.Hyphen))
  use value <- do(nibble.optional(node_parser(indent)))

  value
  |> option.unwrap(yaml.Null)
  |> return
}

fn same_indentation_parser(indent: Int) -> Parser(Nil, Token, Context) {
  use Nil <- do(nibble.token(token.Indentation(indent)))
  return(Nil)
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
    True -> sequence_parser(indent)
    False -> fail()
  }
}

fn fail() -> Parser(a, Token, Context) {
  nibble.fail("Expected a matching indentation")
}

fn node_parser(indent: Int) -> Parser(Yaml, Token, Context) {
  nibble.one_of([
    nibble.lazy(fn() { nested_sequence_parser(indent) }),
    nibble.lazy(flow_sequence.parser),
    nibble.lazy(flow_mapping.parser),
    double_quoted.parser(),
    single_quoted.parser(),
    scalar.parser(),
  ])
}
