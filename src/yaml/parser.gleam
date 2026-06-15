import gleam/float
import gleam/int
import gleam/option.{type Option, None, Some}
import gleam/regexp
import gleam/result
import gleam/string
import nibble.{type Parser}
import nibble/lexer
import yaml.{type Yaml}
import yaml/error.{type YamlError}
import yaml/lexer/context.{type Context}
import yaml/token.{type Token}

pub fn parse(tokens: List(lexer.Token(Token))) -> Result(Yaml, YamlError) {
  tokens
  |> nibble.run(parser())
  |> result.map_error(error.from_parse_errors)
}

fn parser() -> Parser(Yaml, Token, Context) {
  default_parser()
}

fn default_parser() -> Parser(Yaml, Token, Context) {
  nibble.one_of([
    value_parser(),
  ])
}

fn value_parser() -> Parser(Yaml, Token, Context) {
  use tok <- nibble.take_map("Expected a value")
  case tok {
    token.DoubleQuotedScalar(value:)
    | token.SingleQuotedScalar(value:)
    | token.PlainScalar(value:) -> {
      parse_scalar(value)
    }

    token.Hyphen
    | token.QuestionMark
    | token.Colon
    | token.Comma
    | token.OpenMapping
    | token.CloseSequence
    | token.OpenSequence
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
    | token.Indentation(_) -> None
  }
}

fn parse_scalar(value: String) -> Option(Yaml) {
  value
  |> parse_null()
  |> option.or(parse_bool(value))
  |> option.or(parse_int(value))
  |> option.or(parse_octal(value))
  |> option.or(parse_hexadecimal(value))
  |> option.or(parse_float(value))
  |> option.or(parse_inf(value))
  |> option.or(parse_nan(value))
  |> option.or(Some(yaml.String(value)))
}

const regex_options = regexp.Options(case_insensitive: False, multi_line: False)

const null_regex = "null|Null|NULL|~"

fn parse_null(input: String) -> Option(Yaml) {
  let assert Ok(regex) = regexp.compile(null_regex, regex_options)
  case regexp.check(with: regex, content: input) {
    True -> Some(yaml.Null)
    False -> None
  }
}

const bool_regex = "true|True|TRUE|false|False|FALSE"

fn parse_bool(input: String) -> Option(Yaml) {
  let assert Ok(regex) = regexp.compile(bool_regex, regex_options)
  case regexp.check(with: regex, content: input) {
    True -> {
      case string.trim(string.lowercase(input)) {
        "true" -> Some(True)
        "false" -> Some(False)
        _ -> None
      }
      |> option.map(yaml.Bool)
    }
    False -> None
  }
}

const int_regex = "[-+]?[0-9]+"

fn parse_int(input: String) -> Option(Yaml) {
  let assert Ok(regex) = regexp.compile(int_regex, regex_options)
  case regexp.check(with: regex, content: input) {
    True -> {
      case input {
        "+" <> digits -> int.parse(digits)
        "-" <> digits -> int.parse(digits) |> result.map(int.negate)
        _ -> int.parse(input)
      }
      |> option.from_result()
      |> option.map(yaml.Int)
    }
    False -> None
  }
}

const octal_regex = "0o[0-7]+"

fn parse_octal(input: String) -> Option(Yaml) {
  let assert Ok(regex) = regexp.compile(octal_regex, regex_options)
  case regexp.check(with: regex, content: input) {
    True -> {
      case input {
        "0o" <> digits -> {
          int.base_parse(digits, 8)
          |> option.from_result()
          |> option.map(yaml.Int)
        }
        _ -> None
      }
    }
    False -> None
  }
}

const hexadecimal_regex = "0x[0-9a-fA-F]+"

fn parse_hexadecimal(input: String) -> Option(Yaml) {
  let assert Ok(regex) = regexp.compile(hexadecimal_regex, regex_options)
  case regexp.check(with: regex, content: input) {
    True -> {
      case input {
        "0x" <> digits -> {
          int.base_parse(digits, 16)
          |> option.from_result()
          |> option.map(yaml.Int)
        }
        _ -> None
      }
    }
    False -> None
  }
}

const float_regex = "[-+]?(\\.[0-9]+|[0-9]+)\\.([0-9]*)?([eE][-+]?[0-9]+)?"

fn parse_float(input: String) {
  let assert Ok(regex) = regexp.compile(float_regex, regex_options)
  case regexp.scan(with: regex, content: input) {
    [] -> None
    [regexp.Match(content: _, submatches:), ..] ->
      case submatches {
        [Some(integer), None, None] -> {
          float.parse(integer <> ".0")
          |> option.from_result()
        }
        [None, Some(decimal), None] -> {
          float.parse("0." <> decimal)
          |> option.from_result()
        }
        [Some(integer), Some(decimal), None] -> {
          float.parse(integer <> "." <> decimal)
          |> option.from_result()
        }
        [Some(integer), None, Some(float)] -> {
          float.parse(integer <> ".0" <> float)
          |> option.from_result()
        }
        [Some(integer), Some(decimal), Some(float)] -> {
          float.parse(integer <> "." <> decimal <> float)
          |> option.from_result()
        }
        [Some(integer), Some(decimal)] -> {
          float.parse(integer <> "." <> decimal)
          |> option.from_result()
        }
        [Some(integer), None] | [Some(integer)] -> {
          float.parse(integer <> ".0")
          |> option.from_result()
        }
        _ -> None
      }
      |> option.map(yaml.Float)
  }
}

const inf_regex = "[-+]?(\\.inf|\\.Inf|\\.INF)"

fn parse_inf(input: String) -> Option(Yaml) {
  let assert Ok(regex) = regexp.compile(inf_regex, regex_options)
  case regexp.check(with: regex, content: input) {
    True ->
      case string.lowercase(string.trim(input)) {
        "-" <> _ -> yaml.NegInf
        _ -> yaml.PosInf
      }
      |> Some
    False -> None
  }
}

const nan_regex = "[-+]?(\\.nan|\\.nan|\\.nan)"

fn parse_nan(input: String) -> Option(Yaml) {
  let assert Ok(regex) = regexp.compile(nan_regex, regex_options)
  case regexp.check(with: regex, content: input) {
    True -> Some(yaml.Nan)
    False -> None
  }
}
