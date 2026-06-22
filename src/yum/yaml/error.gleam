//// Errors returned by YAML parsing.
////
//// Import this module when you need to pattern match on parsing failures from
//// [`yum/yaml.parse`](../yaml.html#parse) or [`yum/yaml.parse_ast`](../yaml.html#parse_ast).
////

import nibble
import nibble/lexer
import yum/yaml/lexer/context.{type Context}
import yum/yaml/token.{type Token}

pub type YamlError {
  IndentNormalizationError
  LexerError(row: Int, col: Int, lexeme: String)
  MultipleDocuments
  UnexpectedEndOfInput
  UnexpectedToken(token: Token, row: Int, col: Int)
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
    nibble.Custom(_) -> UnexpectedEndOfInput
    nibble.BadParser(_) -> Other(problem)
    nibble.Expected(_, _) -> Other(problem)
  }
}
