import gleam/string
import nibble/lexer.{type Matcher}
import yum/yaml/lexer/context.{type Context}
import yum/yaml/lexer/flow_collection
import yum/yaml/token.{type Token}

pub fn lexer() -> Matcher(Token, Context) {
  use ctx, lexeme, lookahead <- lexer.custom()
  let assert context.FlowMapping(prev:) = ctx
  case lexeme, lookahead {
    " ", _ | "\t", _ | "\r", _ | "\n", _ -> lexer.Drop(ctx)

    "}", _ -> token.CloseMapping |> lexer.Keep(prev)
    ",", _ -> token.Comma |> lexer.Keep(ctx)
    ":", ":" -> lexer.Skip
    ":", _ -> token.Colon |> lexer.Keep(ctx)
    "?", _ -> token.QuestionMark |> lexer.Keep(ctx)
    "[", _ -> token.OpenSequence |> lexer.Keep(context.FlowSequence(ctx))
    "{", _ -> token.OpenMapping |> lexer.Keep(context.FlowMapping(ctx))
    "\"", _ -> token.DoubleQuote |> lexer.Keep(context.DoubleQuotedScalar(ctx))
    "'", _ -> token.SingleQuote |> lexer.Keep(context.SingleQuotedScalar(ctx))

    _, "#" -> {
      case flow_collection.ends_with_whitespace(lexeme) {
        True -> flow_collection.keep_plain_scalar(lexeme, ctx)
        False -> lexer.Skip
      }
    }
    _, ":" -> lexer.Skip
    _, " " | _, "\t" | _, "\r" | _, "\n" ->
      case string.ends_with(lexeme, ":") {
        True -> flow_collection.keep_plain_scalar(lexeme, ctx)
        False -> lexer.Skip
      }
    _, "}" | _, "," | _, "[" | _, "{" | _, "\"" | _, "'" ->
      flow_collection.keep_plain_scalar(lexeme, ctx)
    _, "" -> flow_collection.keep_plain_scalar(lexeme, ctx)
    _, _ -> lexer.Skip
  }
}
