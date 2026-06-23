import gleam/float
import gleam/int
import gleam/list
import gleam/string
import yaml_ast.{type YamlAST}
import yum/yaml/token.{type Token}

pub fn ast(value: YamlAST) -> String {
  case value {
    yaml_ast.Null -> "Null"
    yaml_ast.Bool(value) -> "Bool(" <> bool(value) <> ")"
    yaml_ast.Int(value) -> "Int(" <> int.to_string(value) <> ")"
    yaml_ast.Float(value) -> "Float(" <> float.to_string(value) <> ")"
    yaml_ast.PosInf -> "PosInf"
    yaml_ast.NegInf -> "NegInf"
    yaml_ast.Nan -> "Nan"
    yaml_ast.String(value) -> "String(" <> quoted(value) <> ")"
    yaml_ast.Sequence(entries) -> "Sequence(" <> ast_list(entries) <> ")"
    yaml_ast.Mapping(entries) -> "Mapping(" <> ast_pairs(entries) <> ")"
  }
}

pub fn asts(values: List(YamlAST)) -> String {
  ast_list(values)
}

pub fn tokens(values: List(Token)) -> String {
  values
  |> list.map(token)
  |> string.join(", ")
  |> wrap("[", "]")
}

fn token(value: Token) -> String {
  case value {
    token.Hyphen -> "Hyphen"
    token.QuestionMark -> "QuestionMark"
    token.Colon -> "Colon"
    token.Comma -> "Comma"
    token.OpenSequence -> "OpenSequence"
    token.CloseSequence -> "CloseSequence"
    token.OpenMapping -> "OpenMapping"
    token.CloseMapping -> "CloseMapping"
    token.Hash -> "Hash"
    token.DocumentStart -> "DocumentStart"
    token.DocumentEnd -> "DocumentEnd"
    token.Ampersand -> "Ampersand"
    token.Asterisk -> "Asterisk"
    token.Exclamation -> "Exclamation"
    token.VerticalBar -> "VerticalBar"
    token.GreaterThan -> "GreaterThan"
    token.SingleQuote -> "SingleQuote"
    token.DoubleQuote -> "DoubleQuote"
    token.Percent -> "Percent"
    token.At -> "At"
    token.GraveAccent -> "GraveAccent"
    token.LineBreak -> "LineBreak"
    token.Indentation(value) -> "Indentation(" <> int.to_string(value) <> ")"
    token.DoubleQuotedScalar(value) ->
      "DoubleQuotedScalar(" <> quoted(value) <> ")"
    token.SingleQuotedScalar(value) ->
      "SingleQuotedScalar(" <> quoted(value) <> ")"
    token.MappingKey(value) -> "MappingKey(" <> quoted(value) <> ")"
    token.PlainScalar(value) -> "PlainScalar(" <> quoted(value) <> ")"
    token.Anchor(value) -> "Anchor(" <> quoted(value) <> ")"
    token.Alias(value) -> "Alias(" <> quoted(value) <> ")"
    token.Tag(value) -> "Tag(" <> quoted(value) <> ")"
    token.BlockScalarHeader(style:, chomp:, parent_indent:) ->
      "BlockScalarHeader("
      <> block_scalar_style(style)
      <> ", "
      <> render_chomp(chomp)
      <> ", "
      <> int.to_string(parent_indent)
      <> ")"
    token.BlockScalarLine(indent:, content:) ->
      "BlockScalarLine("
      <> int.to_string(indent)
      <> ", "
      <> quoted(content)
      <> ")"
    token.Directive(name:, parameters:) ->
      "Directive(" <> quoted(name) <> ", " <> string_list(parameters) <> ")"
    token.Escape(value) -> "Escape(" <> quoted(value) <> ")"
    token.InvalidEscape -> "InvalidEscape"
  }
}

fn ast_list(values: List(YamlAST)) -> String {
  values
  |> list.map(ast)
  |> string.join(", ")
  |> wrap("[", "]")
}

fn ast_pairs(values: List(#(YamlAST, YamlAST))) -> String {
  values
  |> list.map(fn(entry) {
    let #(key, value) = entry
    case key {
      yaml_ast.Null -> "Null(" <> ast(value) <> ")"
      _ -> "#(" <> ast(key) <> ", " <> ast(value) <> ")"
    }
  })
  |> string.join(", ")
  |> wrap("[", "]")
}

fn string_list(values: List(String)) -> String {
  values
  |> list.map(quoted)
  |> string.join(", ")
  |> wrap("[", "]")
}

fn block_scalar_style(style: token.BlockScalarStyle) -> String {
  case style {
    token.Literal -> "Literal"
    token.Folded -> "Folded"
  }
}

fn render_chomp(chomp: token.Chomp) -> String {
  case chomp {
    token.Clip -> "Clip"
    token.Strip -> "Strip"
    token.Keep -> "Keep"
  }
}

fn bool(value: Bool) -> String {
  case value {
    True -> "True"
    False -> "False"
  }
}

fn quoted(value: String) -> String {
  string.inspect(value)
}

fn wrap(value: String, prefix: String, suffix: String) -> String {
  prefix <> value <> suffix
}
