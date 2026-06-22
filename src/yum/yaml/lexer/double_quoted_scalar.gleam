import gleam/string
import nibble/lexer.{type Matcher}
import yum/yaml/lexer/context.{type Context}
import yum/yaml/token.{type Token}

pub fn lexer() -> Matcher(Token, Context) {
  use ctx, lexeme, lookahead <- lexer.custom()
  let assert context.DoubleQuotedScalar(prev:) = ctx
  case lexeme, lookahead {
    "\"", _ -> token.DoubleQuote |> lexer.Keep(prev)
    "\\", _ -> lexer.Drop(context.DoubleQuotedEscape(ctx))

    l, "\"" -> token.DoubleQuotedScalar(l) |> lexer.Keep(ctx)
    l, "\\" -> token.DoubleQuotedScalar(l) |> lexer.Keep(ctx)

    _, _ -> lexer.Skip
  }
}

pub fn escape_lexer() -> Matcher(Token, Context) {
  use ctx, lexeme, _lookahead <- lexer.custom()
  let assert context.DoubleQuotedEscape(prev:) = ctx
  case lexeme {
    // Escaped ASCII null (x00) character.
    "0" -> lexer.Keep(token.Escape(lexeme), prev)
    // Escaped ASCII bell (x07) character.
    "a" -> lexer.Keep(token.Escape(lexeme), prev)
    // Escaped ASCII backspace (x08) character.
    "b" -> lexer.Keep(token.Escape(lexeme), prev)
    // Escaped ASCII horizontal tab (x09) character.
    //This is useful at the start or the end of a line to force a leading or trailing tab to become part of the content. [45] ns-esc-horizontal-tab ::=
    "t" -> lexer.Keep(token.Escape(lexeme), prev)
    // Escaped ASCII line feed (x0A) character.
    "n" -> lexer.Keep(token.Escape(lexeme), prev)
    // Escaped ASCII vertical tab (x0B) character.
    "v" -> lexer.Keep(token.Escape(lexeme), prev)
    // Escaped ASCII form feed (x0C) character.
    "f" -> lexer.Keep(token.Escape(lexeme), prev)
    // Escaped ASCII carriage return (x0D) character.
    "r" -> lexer.Keep(token.Escape(lexeme), prev)
    // Escaped ASCII escape (x1B) character.
    "e" -> lexer.Keep(token.Escape(lexeme), prev)
    // Escaped ASCII space (x20) character.
    // This is useful at the start or the end of a line to force a leading or trailing space to become part of the content.
    " " -> lexer.Keep(token.Escape(lexeme), prev)
    // Escaped ASCII double quote (x22).
    "\"" -> lexer.Keep(token.Escape(lexeme), prev)
    // Escaped ASCII slash (x2F), for JSON compatibility.
    "/" -> lexer.Keep(token.Escape(lexeme), prev)
    // Escaped ASCII back slash (x5C).
    "\\" -> lexer.Keep(token.Escape(lexeme), prev)
    // Escaped Unicode next line (x85) character.
    "N" -> lexer.Keep(token.Escape(lexeme), prev)
    // Escaped Unicode non-breaking space (xA0) character.
    "_" -> lexer.Keep(token.Escape(lexeme), prev)
    // Escaped Unicode line separator (x2028) character.
    "L" -> lexer.Keep(token.Escape(lexeme), prev)
    // Escaped Unicode paragraph separator (x2029) character.
    "P" -> lexer.Keep(token.Escape(lexeme), prev)
    // Escaped 8-bit Unicode character.
    "x" <> ns_hex_digit_2 ->
      case string.length(ns_hex_digit_2) {
        2 -> lexer.Keep(token.Escape(lexeme), prev)
        _ -> lexer.Skip
      }
    // Escaped 16-bit Unicode character.
    "u" <> ns_hex_digit_4 ->
      case string.length(ns_hex_digit_4) {
        4 -> lexer.Keep(token.Escape(lexeme), prev)
        _ -> lexer.Skip
      }
    // Escaped 32-bit Unicode character.
    "U" <> ns_hex_digit_8 ->
      case string.length(ns_hex_digit_8) {
        8 -> lexer.Keep(token.Escape(lexeme), prev)
        _ -> lexer.Skip
      }

    "\n" -> lexer.Keep(token.Escape(lexeme), prev)
    "" -> lexer.Skip
    _ -> lexer.Keep(token.InvalidEscape, prev)
  }
}
