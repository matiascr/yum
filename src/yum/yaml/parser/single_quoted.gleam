import gleam/option.{None, Some}
import gleam/string
import nibble.{type Parser, do, return}
import yum/yaml/lexer/context.{type Context}
import yum/yaml/node.{type Node}
import yum/yaml/parser/double_quoted
import yum/yaml/parser/span
import yum/yaml/token.{type Token}

pub fn parser() -> Parser(Node, Token, Context) {
  use _ <- do(nibble.token(token.SingleQuote))
  use start <- do(nibble.span())
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
        | token.DocumentStart
        | token.DocumentEnd
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
        | token.Indentation(..)
        | token.DoubleQuotedScalar(..)
        | token.MappingKey(..)
        | token.PlainScalar(..)
        | token.Anchor(..)
        | token.Alias(..)
        | token.Tag(..)
        | token.BlockScalarHeader(..)
        | token.BlockScalarLine(..)
        | token.Directive(..)
        | token.Escape(..)
        | token.InvalidEscape -> None
      }
    }),
  )
  use end <- do(nibble.span())

  parts
  |> string.concat()
  |> double_quoted.fold_scalar(False)
  |> node.String
  |> node.new(span: span.between(start, end), style: node.SingleQuotedScalar)
  |> return
}
