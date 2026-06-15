import gleam/result
import nibble/lexer.{type Lexer}
import yaml/error.{type YamlError}
import yaml/lexer/context.{type Context}
import yaml/lexer/double_quoted_scalar
import yaml/lexer/flow_mapping
import yaml/lexer/flow_sequence
import yaml/lexer/indentation
import yaml/lexer/plain_scalar
import yaml/lexer/single_quoted_scalar
import yaml/token.{type Token}

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
        indentation.lexer(),
      ]

      // Flow Style Productions
      context.FlowStyle(prev: _) -> [plain_scalar.lexer()]
      context.FlowMapping(prev: _) -> [flow_mapping.lexer()]
      context.FlowSequence(prev: _) -> [flow_sequence.lexer()]
      context.DoubleQuotedScalar(prev: _) -> [double_quoted_scalar.lexer()]
      context.SingleQuotedScalar(prev: _) -> [single_quoted_scalar.lexer()]
      context.DoubleQuotedEscape(prev: _) -> [
        double_quoted_scalar.escape_lexer(),
      ]
    }
  })
}
