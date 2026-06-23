import gleam/bool
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import nibble/lexer.{type Matcher}
import yum/yaml/lexer/context.{type Context}
import yum/yaml/token.{type Token}

pub fn lexer() -> Matcher(Token, Context) {
  use ctx, lexeme, lookahead <- lexer.custom()

  use <- bool.guard(current_indent(ctx) != 0, lexer.NoMatch)
  use <- bool.guard(!string.starts_with(lexeme, "%"), lexer.NoMatch)

  case lookahead {
    "\n" | "" ->
      case directive(lexeme) {
        Some(directive) -> directive |> lexer.Keep(ctx)
        None -> lexer.NoMatch
      }
    _ -> lexer.NoMatch
  }
}

fn directive(lexeme: String) -> Option(Token) {
  let parts =
    lexeme
    |> string.drop_start(1)
    |> string.trim()
    |> string.split(" ")
    |> list.filter(keeping: fn(part) { !string.is_empty(part) })

  case parts {
    [name, ..parameters] -> Some(token.Directive(name:, parameters:))
    _ -> None
  }
}

fn current_indent(ctx: Context) -> Int {
  case ctx {
    context.BlockStyle(indent:) -> indent

    context.FlowStyle(prev:)
    | context.FlowMapping(prev:)
    | context.FlowSequence(prev:)
    | context.BlockScalar(prev:, parent_indent: _)
    | context.DoubleQuotedScalar(prev:)
    | context.SingleQuotedScalar(prev:)
    | context.DoubleQuotedEscape(prev:) -> current_indent(prev)
  }
}
