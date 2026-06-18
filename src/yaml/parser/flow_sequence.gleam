import gleam/option
import nibble.{type Parser, do, return}
import yaml.{type Yaml}
import yaml/lexer/context.{type Context}
import yaml/parser/double_quoted
import yaml/parser/scalar
import yaml/parser/single_quoted
import yaml/token.{type Token}

pub fn parser() -> Parser(Yaml, Token, Context) {
  use _ <- do(nibble.token(token.OpenSequence))
  use entries <- do(nibble.sequence(
    nibble.optional(value_parser()),
    separator: nibble.token(token.Comma),
  ))
  use _ <- do(nibble.optional(nibble.token(token.Comma)))
  use _ <- do(nibble.token(token.CloseSequence))

  entries
  |> option.values()
  |> yaml.Sequence
  |> return
}

fn value_parser() -> Parser(Yaml, Token, Context) {
  nibble.one_of([
    nibble.lazy(parser),
    double_quoted.parser(),
    single_quoted.parser(),
    scalar.parser(),
  ])
}
