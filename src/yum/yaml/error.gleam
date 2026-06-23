//// Errors returned by YAML parsing.
////
//// Import this module when you need to pattern match on parsing failures from
//// [`yum/yaml.parse`](../yaml.html#parse).
////

import gleam/option.{type Option, None, Some}
import gleam/string
import nibble
import nibble/lexer
import yum/yaml/lexer/context.{type Context}
import yum/yaml/node
import yum/yaml/token.{type Token}

pub type YamlError {
  /// Input indentation could not be normalized before lexing.
  IndentNormalizationError

  /// The lexer could not match the input at the given row and column.
  LexerError(row: Int, col: Int, lexeme: String)

  /// A single-document API was given a stream with more than one document.
  MultipleDocuments

  /// The parser reached the end of input before a complete document was found.
  UnexpectedEndOfInput

  /// The parser found a token that was not valid in the current position.
  UnexpectedToken(token: Token, row: Int, col: Int)

  /// Any parser error that does not map cleanly to a more specific variant.
  Other(nibble.Error(Token))
}

pub fn from_lex_error(error: lexer.Error) -> YamlError {
  let lexer.NoMatchFound(row:, col:, lexeme:) = error
  LexerError(row:, col:, lexeme:)
}

pub fn from_parse_errors(
  errors: List(nibble.DeadEnd(Token, Context)),
) -> YamlError {
  // nibble surfaces the furthest-reached error first
  case errors {
    [] -> UnexpectedEndOfInput
    [nibble.DeadEnd(pos:, problem:, ..), ..] -> from_problem(problem, pos)
  }
}

fn from_problem(problem: nibble.Error(Token), pos: lexer.Span) -> YamlError {
  case problem {
    nibble.Unexpected(token) ->
      UnexpectedToken(token:, row: pos.row_start, col: pos.col_start)
    nibble.EndOfInput -> UnexpectedEndOfInput
    // nibble.Custom is reserved for semantic errors threaded out via
    // parser user state — see Issues. This branch should not be reached
    // through from_parse_errors in normal operation.
    nibble.Custom(..) -> UnexpectedEndOfInput
    nibble.BadParser(..) -> Other(problem)
    nibble.Expected(..) -> Other(problem)
  }
}

/// Renders a human-readable parse error message.
///
pub fn message(error: YamlError) -> String {
  case error {
    IndentNormalizationError -> "Could not normalize YAML indentation"
    LexerError(lexeme:, ..) -> "Could not lex YAML near `" <> lexeme <> "`"
    MultipleDocuments -> "Expected a single YAML document"
    UnexpectedEndOfInput -> "Unexpected end of YAML input"
    UnexpectedToken(token:, ..) ->
      "Unexpected YAML token `" <> token_label(token) <> "`"
    Other(..) -> "Could not parse YAML"
  }
}

/// Returns the primary source span for a parse error, when one is available.
///
pub fn span(error: YamlError) -> Option(node.Span) {
  case error {
    LexerError(row:, col:, lexeme:) ->
      Some(point_span(row, col, width: string.length(lexeme)))

    UnexpectedToken(row:, col:, ..) -> Some(point_span(row, col, width: 1))

    IndentNormalizationError
    | MultipleDocuments
    | UnexpectedEndOfInput
    | Other(..) -> None
  }
}

fn point_span(row: Int, col: Int, width width: Int) -> node.Span {
  let width = case width <= 0 {
    True -> 1
    False -> width
  }

  node.Span(
    start: node.Position(row, col),
    end: node.Position(row, col + width),
  )
}

fn token_label(token: Token) -> String {
  case token {
    token.Hyphen -> "-"
    token.QuestionMark -> "?"
    token.Colon -> ":"
    token.Comma -> ","
    token.OpenSequence -> "["
    token.CloseSequence -> "]"
    token.OpenMapping -> "{"
    token.CloseMapping -> "}"
    token.Hash -> "#"
    token.DocumentStart -> "---"
    token.DocumentEnd -> "..."
    token.Ampersand -> "&"
    token.Asterisk -> "*"
    token.Exclamation -> "!"
    token.VerticalBar -> "|"
    token.GreaterThan -> ">"
    token.SingleQuote -> "'"
    token.DoubleQuote -> "\""
    token.Percent -> "%"
    token.At -> "@"
    token.GraveAccent -> "`"
    token.LineBreak -> "\\n"
    token.Indentation(..) -> "indentation"
    token.DoubleQuotedScalar(..) -> "double_quoted_scalar"
    token.SingleQuotedScalar(..) -> "single_quoted_scalar"
    token.MappingKey(..) -> "mapping_key"
    token.PlainScalar(..) -> "plain_scalar"
    token.Anchor(..) -> "anchor"
    token.Alias(..) -> "alias"
    token.Tag(..) -> "tag"
    token.BlockScalarHeader(..) -> "block_scalar_header"
    token.BlockScalarLine(..) -> "block_scalar_line"
    token.Directive(name:, ..) -> "directive(" <> name <> ")"
    token.Escape(..) -> "escape"
    token.InvalidEscape -> "invalid_escape"
  }
}
