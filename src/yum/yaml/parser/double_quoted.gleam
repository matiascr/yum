import gleam/bit_array
import gleam/bool
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import nibble.{type Parser, do, return}
import yum/yaml/lexer/context.{type Context}
import yum/yaml/node.{type YamlNode}
import yum/yaml/parser/span
import yum/yaml/token.{type Token}

/// Raw text and escape tokens need different folding rules, especially around
/// escaped line breaks.
type DoubleQuotedElement {
  Raw(String)
  Escaped(String)
  EscapedLineBreak
}

pub fn parser() -> Parser(YamlNode, Token, Context) {
  use _ <- do(nibble.token(token.DoubleQuote))
  use start <- do(nibble.span())
  use elements <- do(
    nibble.many({
      use token <- nibble.take_map("Expected a double quoted value")
      case token {
        token.DoubleQuotedScalar(value:) -> Some(Raw(value))
        token.Escape(value:) -> parse_escape(value)
        _ -> None
      }
    }),
  )
  use _ <- do(nibble.token(token.DoubleQuote))
  use end <- do(nibble.span())

  elements
  |> render_elements()
  |> node.String
  |> node.new(span: span.between(start, end), style: node.DoubleQuotedScalar)
  |> return
}

fn render_elements(elements: List(DoubleQuotedElement)) -> String {
  render_elements_loop(elements, False, [])
  |> list.reverse()
  |> string.concat()
}

fn render_elements_loop(
  elements: List(DoubleQuotedElement),
  strip_prefix: Bool,
  parts: List(String),
) -> List(String) {
  case elements {
    [] -> parts
    [Raw(value), ..rest] -> {
      let #(value, strip_prefix) = case strip_prefix {
        True -> strip_double_escaped_prefix(value, rest)
        False -> #(value, False)
      }

      render_elements_loop(rest, strip_prefix, [
        fold_scalar(value, next_is_escaped_line_break(rest)),
        ..parts
      ])
    }

    [Escaped(value), ..rest] ->
      render_elements_loop(rest, False, [value, ..parts])

    [EscapedLineBreak, ..rest] -> render_elements_loop(rest, True, parts)
  }
}

/// An escaped line break skips the line break and the indentation that follows
/// it. If the prefix spans multiple raw/escape elements, keep stripping until
/// the next non-empty raw chunk or explicit escape.
fn strip_double_escaped_prefix(
  value: String,
  rest: List(DoubleQuotedElement),
) -> #(String, Bool) {
  let stripped = drop_leading_whitespace(value)

  case string.is_empty(stripped), rest {
    True, [Escaped(_), ..] -> #(stripped, False)
    True, [] -> #(stripped, False)
    True, _ -> #(stripped, True)
    False, _ -> #(stripped, False)
  }
}

fn next_is_escaped_line_break(elements: List(DoubleQuotedElement)) -> Bool {
  case elements {
    [EscapedLineBreak, ..] -> True
    _ -> False
  }
}

/// Normalizes new lines and whitespace according to YAML flow folding.
///
/// When the next element is an escaped line break, trailing whitespace before
/// that escape must be preserved instead of discarded.
pub fn fold_scalar(
  scalar: String,
  preserve_trailing_whitespace: Bool,
) -> String {
  use <- bool.guard(when: scalar == "", return: "")
  use <- bool.guard(when: !string.contains(scalar, "\n"), return: scalar)

  let #(scalar, preserved_trailing_whitespace) = case
    preserve_trailing_whitespace
  {
    True -> split_trailing_whitespace(scalar)
    False -> #(scalar, "")
  }

  let #(trimmed, ends_with_whitespace) =
    scalar
    |> string.split("\n")
    |> fold_flow_lines()

  let lead_padded = case starts_with_whitespace(scalar) {
    True -> " " <> trimmed
    False -> trimmed
  }

  let end_padded = case preserve_trailing_whitespace, ends_with_whitespace {
    True, _ -> lead_padded
    False, True -> lead_padded <> " "
    False, False -> lead_padded
  }

  end_padded <> preserved_trailing_whitespace
}

fn fold_flow_lines(lines: List(String)) -> #(String, Bool) {
  let #(parts, ends_with_whitespace) = fold_flow_lines_loop(lines, [], 0, False)

  #(
    parts
      |> list.reverse()
      |> string.concat(),
    ends_with_whitespace,
  )
}

fn fold_flow_lines_loop(
  lines: List(String),
  parts: List(String),
  empty_lines: Int,
  ends_with_whitespace: Bool,
) -> #(List(String), Bool) {
  case lines {
    [] -> #(parts, ends_with_whitespace)
    [line, ..rest] -> {
      let #(line, ends_with_whitespace) = trim_whitespace(line)

      case string.is_empty(line), parts {
        // Empty physical lines fold to line feeds before the next non-empty
        // line. Leading empty lines are ignored because there is no content yet.
        True, _ ->
          fold_flow_lines_loop(
            rest,
            parts,
            empty_lines + 1,
            ends_with_whitespace,
          )
        False, [] -> fold_flow_lines_loop(rest, [line], 0, ends_with_whitespace)
        False, [_, ..] -> {
          let separator = case empty_lines > 0 {
            True -> string.repeat("\n", empty_lines)
            False -> " "
          }

          fold_flow_lines_loop(
            rest,
            [line, separator, ..parts],
            0,
            ends_with_whitespace,
          )
        }
      }
    }
  }
}

fn starts_with_whitespace(s: String) -> Bool {
  case s {
    " " <> _ | "\t" <> _ | "\r" <> _ | "\n" <> _ -> True
    _ -> False
  }
}

/// Returns the trimmed line and whether the original line ended in whitespace.
/// Empty or all-whitespace lines count as ending in whitespace.
fn trim_whitespace(s: String) -> #(String, Bool) {
  let without_leading = drop_leading_whitespace(s)
  let #(without_trailing, has_trailing_whitespace) =
    drop_trailing_whitespace(without_leading)

  #(
    without_trailing,
    string.is_empty(s)
      || { !string.is_empty(s) && string.is_empty(without_leading) }
      || has_trailing_whitespace,
  )
}

fn drop_leading_whitespace(s: String) -> String {
  case s {
    " " <> rest | "\t" <> rest | "\r" <> rest | "\n" <> rest ->
      drop_leading_whitespace(rest)
    _ -> s
  }
}

fn split_trailing_whitespace(s: String) -> #(String, String) {
  let #(content_length, _) = trailing_whitespace(s, 0, 0)
  #(
    string.slice(s, at_index: 0, length: content_length),
    string.drop_start(s, content_length),
  )
}

fn drop_trailing_whitespace(s: String) -> #(String, Bool) {
  let #(content_length, has_trailing_whitespace) = trailing_whitespace(s, 0, 0)

  case has_trailing_whitespace {
    True -> #(string.slice(s, at_index: 0, length: content_length), True)
    False -> #(s, False)
  }
}

fn trailing_whitespace(
  s: String,
  content_length: Int,
  pending_whitespace: Int,
) -> #(Int, Bool) {
  case s {
    "" -> #(content_length, pending_whitespace > 0)
    " " <> rest | "\t" <> rest | "\r" <> rest | "\n" <> rest ->
      trailing_whitespace(rest, content_length, pending_whitespace + 1)
    _ -> {
      // Whitespace is only known to be content once a later non-whitespace
      // grapheme proves it was not trailing whitespace.
      let assert Ok(#(_, rest)) = string.pop_grapheme(s)
      trailing_whitespace(rest, content_length + pending_whitespace + 1, 0)
    }
  }
}

/// Turns escaped characters into their corresponding UTF equivalent.
fn parse_escape(s: String) -> Option(DoubleQuotedElement) {
  case s {
    // Escaped ASCII null (x00) character.
    "0" -> Some(Escaped("\u{00}"))
    // Escaped ASCII bell (x07) character.
    "a" -> Some(Escaped("\u{07}"))
    // Escaped ASCII backspace (x08) character.
    "b" -> Some(Escaped("\u{08}"))
    // Escaped ASCII horizontal tab (x09) character.
    // This is useful at the start or the end of a line to force a leading or
    // trailing tab to become part of the content.
    "t" -> Some(Escaped("\u{09}"))
    // Escaped ASCII line feed (x0A) character.
    "n" -> Some(Escaped("\u{0A}"))
    // Escaped ASCII vertical tab (x0B) character.
    "v" -> Some(Escaped("\u{0B}"))
    // Escaped ASCII form feed (x0C) character.
    "f" -> Some(Escaped("\u{0C}"))
    // Escaped ASCII carriage return (x0D) character.
    "r" -> Some(Escaped("\u{0D}"))
    // Escaped ASCII escape (x1B) character.
    "e" -> Some(Escaped("\u{1B}"))
    // Escaped ASCII space (x20) character.
    // This is useful at the start or the end of a line to force a leading or
    // trailing space to become part of the content.
    " " -> Some(Escaped("\u{20}"))
    // Escaped ASCII double quote (x22).
    "\"" -> Some(Escaped("\u{22}"))
    // Escaped ASCII slash (x2F), for JSON compatibility.
    "/" -> Some(Escaped("\u{2F}"))
    // Escaped ASCII back slash (x5C).
    "\\" -> Some(Escaped("\u{5C}"))
    // Escaped Unicode next line (x85) character.
    "N" -> Some(Escaped("\u{85}"))
    // Escaped Unicode non-breaking space (xA0) character.
    "_" -> Some(Escaped("\u{A0}"))
    // Escaped Unicode line separator (x2028) character.
    "L" -> Some(Escaped("\u{2028}"))
    // Escaped Unicode paragraph separator (x2029) character.
    "P" -> Some(Escaped("\u{2029}"))

    // Escaped 8-bit Unicode character.
    "x" <> ns_hex_digit_2 -> decode_codepoint(ns_hex_digit_2, 2)

    // Escaped 16-bit Unicode character.
    "u" <> ns_hex_digit_4 -> decode_codepoint(ns_hex_digit_4, 4)

    // Escaped 32-bit Unicode character.
    "U" <> ns_hex_digit_8 -> decode_codepoint(ns_hex_digit_8, 8)

    "\n" -> Some(EscapedLineBreak)

    _ -> None
  }
}

fn decode_codepoint(hex_digits: String, nof_digits: Int) {
  option.from_result({
    use bits <- result.try(bit_array.base16_decode(hex_digits))
    let size = nof_digits * 4
    case bits {
      <<codepoint:size(size)-int>> -> {
        codepoint
        |> string.utf_codepoint()
        |> result.map(list.wrap)
        |> result.map(string.from_utf_codepoints)
        |> result.map(Escaped)
      }
      _ -> Error(Nil)
    }
  })
}
