import gleam/option
import yum/yaml
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

pub fn malformed_yaml_fallback_errors_keep_source_spans_test() {
  assert_parse_error_with_span("\"bad \\q escape\"", "Could not parse YAML")
  assert_parse_error_with_span("[one, two", "Could not parse YAML")
  assert_parse_error_with_span("[one, two}", "Could not parse YAML")
}

pub fn malformed_yaml_unexpected_tokens_keep_messages_and_spans_test() {
  assert_parse_error(
    "key:\n  child: value\n sibling: value",
    "Unexpected YAML token `mapping_key`",
    option.Some(span(3, 2, 3, 3)),
  )
  assert_parse_error(
    "key: |\nvalue",
    "Unexpected YAML token `plain_scalar`",
    option.Some(span(2, 1, 2, 2)),
  )
}

pub fn multiple_documents_surface_public_parse_error_test() {
  assert_parse_error(
    "---\none\n---\ntwo",
    "Expected a single YAML document",
    option.None,
  )
}

fn assert_parse_error(
  input: String,
  expected_message: String,
  expected_span: option.Option(node.Span),
) {
  let assert Error(parse_error) = yaml.parse(input)

  assert error.message(parse_error) == expected_message
  assert error.span(parse_error) == expected_span
}

fn assert_parse_error_with_span(input: String, expected_message: String) {
  let assert Error(parse_error) = yaml.parse(input)

  assert error.message(parse_error) == expected_message
  let assert option.Some(_) = error.span(parse_error)
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
