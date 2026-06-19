import gleam/string
import nibble/lexer.{type Matcher}
import yaml/lexer/context.{type Context}
import yaml/token.{type Token}

pub fn lexer() -> Matcher(Token, Context) {
  use ctx, lexeme, lookahead <- lexer.custom()
  case lexeme, lookahead {
    " ", _ | "\t", _ | "\r", _ -> lexer.Drop(ctx)

    "\n" <> _, " " -> lexer.Skip
    "\n" <> _, "\t" -> lexer.Skip
    "\n" <> _, "\n" -> lexer.Drop(ctx)
    "\n" <> _, "" -> lexer.Drop(ctx)
    "\n" <> spaces, _ -> {
      let indent = string.length(spaces)

      indent
      |> token.Indentation
      |> lexer.Keep(context.FlowStyle(prev: context.BlockStyle(indent: indent)))
    }

    "-", " " | "-", "\n" | "-", "" -> {
      let indent = current_indent(ctx)
      token.Hyphen
      |> lexer.Keep(context.FlowStyle(prev: context.BlockStyle(indent: indent)))
    }

    _, _ -> lexer.NoMatch
  }
}

fn current_indent(ctx: Context) -> Int {
  case ctx {
    context.BlockStyle(indent:) -> indent

    context.FlowStyle(prev:)
    | context.FlowMapping(prev:)
    | context.FlowSequence(prev:)
    | context.DoubleQuotedScalar(prev:)
    | context.SingleQuotedScalar(prev:)
    | context.DoubleQuotedEscape(prev:) -> current_indent(prev)
  }
}
