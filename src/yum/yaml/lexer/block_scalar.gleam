import gleam/option.{type Option, None, Some}
import gleam/string
import nibble/lexer.{type Matcher}
import yum/yaml/lexer/context.{type Context}
import yum/yaml/token.{type Token}

pub fn lexer() -> Matcher(Token, Context) {
  use ctx, lexeme, lookahead <- lexer.custom()
  let assert context.BlockScalar(prev:, parent_indent:) = ctx

  case lexeme, lookahead {
    "\n", "" -> lexer.Drop(prev)
    "\n", "\n" -> token.BlockScalarLine(0, "") |> lexer.Keep(ctx)

    "\n" <> line, "\n" | "\n" <> line, "" -> {
      let #(indent, content) = split_indent(line)
      token.BlockScalarLine(indent, content) |> lexer.Keep(ctx)
    }

    "\n" <> spaces, _ ->
      case only_spaces(spaces), is_line_break(lookahead), lookahead {
        True, False, " " -> lexer.Skip
        True, False, "" -> lexer.Skip
        True, False, _ -> {
          let indent = string.length(spaces)

          case indent <= parent_indent {
            True ->
              token.Indentation(indent)
              |> lexer.Keep(
                context.FlowStyle(prev: context.BlockStyle(indent:)),
              )
            False -> lexer.Skip
          }
        }
        _, _, _ -> lexer.Skip
      }

    _, _ -> lexer.Skip
  }
}

pub fn header(lexeme: String, parent_indent: Int) -> Option(Token) {
  let trimmed = string.trim(lexeme)

  case trimmed {
    "|" ->
      Some(token.BlockScalarHeader(token.Literal, token.Clip, parent_indent))
    "|-" ->
      Some(token.BlockScalarHeader(token.Literal, token.Strip, parent_indent))
    "|+" ->
      Some(token.BlockScalarHeader(token.Literal, token.Keep, parent_indent))
    ">" ->
      Some(token.BlockScalarHeader(token.Folded, token.Clip, parent_indent))
    ">-" ->
      Some(token.BlockScalarHeader(token.Folded, token.Strip, parent_indent))
    ">+" ->
      Some(token.BlockScalarHeader(token.Folded, token.Keep, parent_indent))
    _ -> None
  }
}

fn split_indent(line: String) -> #(Int, String) {
  split_indent_loop(line, 0)
}

fn split_indent_loop(line: String, indent: Int) -> #(Int, String) {
  case line {
    " " <> rest -> split_indent_loop(rest, indent + 1)
    _ -> #(indent, line)
  }
}

fn only_spaces(value: String) -> Bool {
  case value {
    "" -> True
    " " <> rest -> only_spaces(rest)
    _ -> False
  }
}

fn is_line_break(value: String) -> Bool {
  value == "\n" || value == "\r"
}
