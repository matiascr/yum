import gleam/float
import gleam/int
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import nibble.{type Parser}
import yum/yaml/ast.{type YamlAST} as yaml
import yum/yaml/lexer/context.{type Context}
import yum/yaml/token.{type Token}

pub fn parser() -> Parser(YamlAST, Token, Context) {
  use tok <- nibble.take_map("Expected a value")
  case tok {
    token.SingleQuotedScalar(value:) | token.PlainScalar(value:) -> parse(value)
    _ -> None
  }
}

pub fn parse(value: String) -> Option(YamlAST) {
  value
  |> parse_null()
  |> option.or(parse_bool(value))
  |> option.or(parse_int(value))
  |> option.or(parse_octal(value))
  |> option.or(parse_hexadecimal(value))
  |> option.or(parse_inf(value))
  |> option.or(parse_nan(value))
  |> option.or(parse_float(value))
  |> option.or(Some(yaml.String(value)))
}

fn parse_null(input: String) -> Option(YamlAST) {
  case input {
    "null" | "Null" | "NULL" | "~" -> Some(yaml.Null)
    _ -> None
  }
}

fn parse_bool(input: String) -> Option(YamlAST) {
  case input {
    "true" | "True" | "TRUE" -> Some(yaml.Bool(True))
    "false" | "False" | "FALSE" -> Some(yaml.Bool(False))
    _ -> None
  }
}

fn parse_int(input: String) -> Option(YamlAST) {
  case input {
    "+" <> digits -> parse_decimal_int(digits, fn(n) { n })
    "-" <> digits -> parse_decimal_int(digits, int.negate)
    _ -> parse_decimal_int(input, fn(n) { n })
  }
}

fn parse_decimal_int(input: String, sign: fn(Int) -> Int) -> Option(YamlAST) {
  case has_digits(input), all_decimal_digits(input) {
    True, True ->
      input
      |> int.parse()
      |> result.map(sign)
      |> result.map(yaml.Int)
      |> option.from_result()
    _, _ -> None
  }
}

fn parse_octal(input: String) -> Option(YamlAST) {
  case input {
    "0o" <> digits ->
      case has_digits(digits), all_octal_digits(digits) {
        True, True ->
          int.base_parse(digits, 8)
          |> option.from_result()
          |> option.map(yaml.Int)
        _, _ -> None
      }
    _ -> None
  }
}

fn parse_hexadecimal(input: String) -> Option(YamlAST) {
  case input {
    "0x" <> digits ->
      case has_digits(digits), all_hexadecimal_digits(digits) {
        True, True ->
          int.base_parse(digits, 16)
          |> option.from_result()
          |> option.map(yaml.Int)
        _, _ -> None
      }
    _ -> None
  }
}

fn parse_float(input: String) -> Option(YamlAST) {
  case string.contains(input, "."), has_decimal_digit(input) {
    True, True ->
      input
      |> parse_float_value()
      |> option.from_result()
      |> option.map(yaml.Float)
    _, _ -> None
  }
}

fn parse_float_value(input: String) -> Result(Float, Nil) {
  case input {
    "+" <> unsigned -> float.parse(unsigned)
    _ -> float.parse(input)
  }
}

fn parse_inf(input: String) -> Option(YamlAST) {
  case input {
    ".inf" | ".Inf" | ".INF" | "+.inf" | "+.Inf" | "+.INF" -> Some(yaml.PosInf)
    "-.inf" | "-.Inf" | "-.INF" -> Some(yaml.NegInf)
    _ -> None
  }
}

fn parse_nan(input: String) -> Option(YamlAST) {
  case input {
    ".nan" | ".NaN" | ".NAN" -> Some(yaml.Nan)
    _ -> None
  }
}

fn has_digits(input: String) -> Bool {
  !string.is_empty(input)
}

fn has_decimal_digit(input: String) -> Bool {
  case input {
    "" -> False
    "0" <> _
    | "1" <> _
    | "2" <> _
    | "3" <> _
    | "4" <> _
    | "5" <> _
    | "6" <> _
    | "7" <> _
    | "8" <> _
    | "9" <> _ -> True
    _ ->
      case string.pop_grapheme(input) {
        Ok(#(_, rest)) -> has_decimal_digit(rest)
        Error(_) -> False
      }
  }
}

fn all_decimal_digits(input: String) -> Bool {
  case input {
    "" -> True
    "0" <> rest
    | "1" <> rest
    | "2" <> rest
    | "3" <> rest
    | "4" <> rest
    | "5" <> rest
    | "6" <> rest
    | "7" <> rest
    | "8" <> rest
    | "9" <> rest -> all_decimal_digits(rest)
    _ -> False
  }
}

fn all_octal_digits(input: String) -> Bool {
  case input {
    "" -> True
    "0" <> rest
    | "1" <> rest
    | "2" <> rest
    | "3" <> rest
    | "4" <> rest
    | "5" <> rest
    | "6" <> rest
    | "7" <> rest -> all_octal_digits(rest)
    _ -> False
  }
}

fn all_hexadecimal_digits(input: String) -> Bool {
  case input {
    "" -> True
    "0" <> rest
    | "1" <> rest
    | "2" <> rest
    | "3" <> rest
    | "4" <> rest
    | "5" <> rest
    | "6" <> rest
    | "7" <> rest
    | "8" <> rest
    | "9" <> rest
    | "a" <> rest
    | "b" <> rest
    | "c" <> rest
    | "d" <> rest
    | "e" <> rest
    | "f" <> rest
    | "A" <> rest
    | "B" <> rest
    | "C" <> rest
    | "D" <> rest
    | "E" <> rest
    | "F" <> rest -> all_hexadecimal_digits(rest)
    _ -> False
  }
}
