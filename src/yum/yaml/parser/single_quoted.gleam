import gleam/option.{None, Some}
import gleam/string
import nibble.{type Parser, do, return}
import yum/yaml/ast.{type YamlAST} as yaml
import yum/yaml/lexer/context.{type Context}
import yum/yaml/parser/double_quoted
import yum/yaml/token.{type Token}

pub fn parser() -> Parser(YamlAST, Token, Context) {
  use _ <- do(nibble.token(token.SingleQuote))
  use parts <- do(
    nibble.many({
      use tok <- nibble.take_map("Expected a single quoted value")
      case tok {
        token.SingleQuotedScalar(value:) -> Some(value)

        token.Hyphen
        | token.QuestionMark
        | token.Colon
        | token.Comma
        | token.OpenSequence
        | token.CloseSequence
        | token.OpenMapping
        | token.CloseMapping
        | token.Hash
        | token.Ampersand
        | token.Asterisk
        | token.Exclamation
        | token.VerticalBar
        | token.GreaterThan
        | token.SingleQuote
        | token.DoubleQuote
        | token.Percent
        | token.At
        | token.GraveAccent
        | token.LineBreak
        | token.Indentation(_)
        | token.DoubleQuotedScalar(_)
        | token.Escape(_)
        | token.MappingKey(_)
        | token.PlainScalar(_)
        | token.InvalidEscape -> None
      }
    }),
  )

  parts
  |> string.concat()
  |> double_quoted.fold_scalar(False)
  |> yaml.String
  |> return
}
