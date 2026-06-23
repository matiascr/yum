import gleam/option
import yum/yaml/error
import yum/yaml/node
import yum/yaml/token

pub fn lexer_errors_have_messages_and_spans_test() {
  let parse_error = error.LexerError(row: 2, col: 3, lexeme: "@")

  assert error.message(parse_error) == "Could not lex YAML near `@`"
  assert error.span(parse_error) == option.Some(span(2, 3, 2, 4))
}

pub fn unexpected_tokens_have_messages_and_spans_test() {
  let parse_error = error.UnexpectedToken(token: token.Colon, row: 1, col: 5)

  assert error.message(parse_error) == "Unexpected YAML token `:`"
  assert error.span(parse_error) == option.Some(span(1, 5, 1, 6))
}

pub fn spanless_errors_return_no_span_test() {
  assert error.message(error.MultipleDocuments)
    == "Expected a single YAML document"
  assert error.span(error.MultipleDocuments) == option.None
  assert error.message(error.UnexpectedEndOfInput)
    == "Unexpected end of YAML input"
  assert error.span(error.UnexpectedEndOfInput) == option.None
}

fn span(
  start_row: Int,
  start_column: Int,
  end_row: Int,
  end_column: Int,
) -> node.Span {
  node.Span(
    start: node.Position(start_row, start_column),
    end: node.Position(end_row, end_column),
  )
}
