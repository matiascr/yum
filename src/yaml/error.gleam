import nibble/lexer

pub type YamlError {
  IndentNormalizationError
  LexerError(row: Int, col: Int, lexeme: String)
}

pub fn from_lex_error(error: lexer.Error) -> YamlError {
  let lexer.NoMatchFound(row:, col:, lexeme:) = error
  LexerError(row:, col:, lexeme:)
}
