import nibble/lexer.{type Matcher}
import yum/yaml/lexer/context.{type Context}
import yum/yaml/token.{type Token}

pub fn lexer() -> Matcher(Token, Context) {
  use ctx, lexeme, lookahead <- lexer.custom()

  case current_indent(ctx), lexeme, boundary(lookahead) {
    0, "---", True -> token.DocumentStart |> lexer.Keep(ctx)
    0, "...", True -> token.DocumentEnd |> lexer.Keep(ctx)
    _, _, _ -> lexer.NoMatch
  }
}

fn boundary(value: String) -> Bool {
  case value {
    "" | "\n" | "\r" | " " | "\t" -> True
    _ -> False
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
