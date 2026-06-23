import gleam/option.{type Option, None, Some}
import gleam/string
import yum/yaml/token.{type Token}

pub fn token(lexeme: String) -> Option(Token) {
  case string.starts_with(lexeme, "&"), name(lexeme) {
    True, Some(anchor) -> Some(token.Anchor(anchor))
    _, _ ->
      case string.starts_with(lexeme, "*"), name(lexeme) {
        True, Some(alias) -> Some(token.Alias(alias))
        _, _ -> None
      }
  }
}

fn name(lexeme: String) -> Option(String) {
  let name =
    lexeme
    |> string.drop_start(1)
    |> string.trim_end()

  case string.is_empty(name) {
    True -> None
    False -> Some(name)
  }
}
