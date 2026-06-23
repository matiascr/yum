import gleam/result
import nibble/lexer.{type Lexer}
import yum/yaml/error.{type YamlError}
import yum/yaml/lexer/block_scalar
import yum/yaml/lexer/comment
import yum/yaml/lexer/context.{type Context}
import yum/yaml/lexer/directive
import yum/yaml/lexer/document_marker
import yum/yaml/lexer/double_quoted_scalar
import yum/yaml/lexer/flow_mapping
import yum/yaml/lexer/flow_sequence
import yum/yaml/lexer/indentation
import yum/yaml/lexer/plain_scalar
import yum/yaml/lexer/single_quoted_scalar
import yum/yaml/token.{type Token}

pub fn lex(input: String) -> Result(List(lexer.Token(Token)), YamlError) {
  let initial_context: Context = context.FlowStyle(prev: context.BlockStyle(0))

  input
  |> lexer.run_advanced(initial_context, lexer())
  |> result.map_error(error.from_lex_error)
}

fn lexer() -> Lexer(Token, Context) {
  lexer.advanced(fn(ctx) {
    case ctx {
      context.BlockStyle(_) -> [
        comment.lexer(),
        directive.lexer(),
        document_marker.lexer(),
        indentation.lexer(),
      ]

      // Flow Style Productions
      context.FlowStyle(prev: _) -> [
        comment.lexer(),
        directive.lexer(),
        document_marker.lexer(),
        indentation.lexer(),
        plain_scalar.lexer(),
      ]
      context.FlowMapping(prev: _) -> [
        comment.lexer(),
        flow_mapping.lexer(),
      ]
      context.FlowSequence(prev: _) -> [
        comment.lexer(),
        flow_sequence.lexer(),
      ]
      context.BlockScalar(prev: _, parent_indent: _) -> [block_scalar.lexer()]
      context.DoubleQuotedScalar(prev: _) -> [double_quoted_scalar.lexer()]
      context.SingleQuotedScalar(prev: _) -> [single_quoted_scalar.lexer()]
      context.DoubleQuotedEscape(prev: _) -> [
        double_quoted_scalar.escape_lexer(),
      ]
    }
  })
}
