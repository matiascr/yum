//// Errors returned by YAML parsing.
////
//// Import this module when you need to pattern match on parsing failures from
//// [`yum/yaml.parse`](../yaml.html#parse).
////

import nibble
import nibble/lexer
import yum/yaml/lexer/context.{type Context}
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
