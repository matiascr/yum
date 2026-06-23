import gleam/option.{None, Some}
import gleam/string
import nibble/lexer.{type Matcher}
import yum/yaml/lexer/block_scalar
import yum/yaml/lexer/context.{type Context}
import yum/yaml/lexer/node_property
import yum/yaml/token.{type Token}

pub fn lexer() -> Matcher(Token, Context) {
  use ctx, lexeme, lookahead <- lexer.custom()
  let assert context.FlowStyle(prev:) = ctx
  case lexeme, lookahead {
    " ", _ | "\t", _ | "\r", _ -> lexer.Drop(ctx)

    "-", " " | "-", "\n" | "-", "" -> token.Hyphen |> lexer.Keep(ctx)
    "{", _ -> token.OpenMapping |> lexer.Keep(context.FlowMapping(ctx))
    "[", _ -> token.OpenSequence |> lexer.Keep(context.FlowSequence(ctx))
    "\"", _ -> token.DoubleQuote |> lexer.Keep(context.DoubleQuotedScalar(ctx))
    "'", _ -> token.SingleQuote |> lexer.Keep(context.SingleQuotedScalar(ctx))
    "?", " " | "?", "\t" | "?", "\r" | "?", "\n" | "?", "" ->
      token.QuestionMark |> lexer.Keep(ctx)
    ":", " " | ":", "\t" | ":", "\r" | ":", "\n" | ":", "" ->
      token.Colon |> lexer.Keep(ctx)

    _, "\n" | _, "" ->
      case node_property.token(lexeme) {
        Some(property) ->
          case property {
            token.Anchor(..) -> property |> lexer.Keep(ctx)
            token.Alias(..) -> property |> lexer.Keep(prev)
            _ -> property |> lexer.Keep(ctx)
          }
        None ->
          case block_scalar.header(lexeme, current_indent(prev)) {
            Some(header) ->
              header
              |> lexer.Keep(context.BlockScalar(
                prev:,
                parent_indent: current_indent(prev),
              ))
            None -> keep_plain_or_mapping_key(lexeme, ctx, prev)
          }
      }

    _, "#" ->
      case ends_with_whitespace(lexeme) {
        True -> plain_scalar(lexeme) |> lexer.Keep(prev)
        False -> lexer.Skip
      }
    _, " " | _, "\t" | _, "\r" ->
      case node_property.token(lexeme) {
        Some(property) ->
          case property {
            token.Anchor(..) -> property |> lexer.Keep(ctx)
            token.Alias(..) -> property |> lexer.Keep(prev)
            _ -> property |> lexer.Keep(ctx)
          }
        None ->
          case string.ends_with(lexeme, ":") {
            True -> mapping_key(lexeme) |> lexer.Keep(ctx)
            False -> lexer.Skip
          }
      }
    _, _ -> lexer.Skip
  }
}

fn keep_plain_or_mapping_key(lexeme: String, ctx: Context, prev: Context) {
  case string.ends_with(lexeme, ":") {
    True -> mapping_key(lexeme) |> lexer.Keep(ctx)
    False -> plain_scalar(lexeme) |> lexer.Keep(prev)
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

fn ends_with_whitespace(s: String) -> Bool {
  string.ends_with(s, " ")
  || string.ends_with(s, "\t")
  || string.ends_with(s, "\r")
  || string.ends_with(s, "\n")
}

fn mapping_key(lexeme: String) {
  lexeme
  |> string.drop_end(1)
  |> string.trim_end()
  |> token.MappingKey
}

fn plain_scalar(lexeme: String) {
  lexeme
  // Leading whitespace is already being dropped in the lexer
  |> string.trim_end()
  |> token.PlainScalar
}
