import gleam/int
import gleam/list
import gleam/option.{None, Some}
import gleam/string
import nibble.{type Parser, do, return}
import yum/yaml/ast.{type YamlAST} as yaml
import yum/yaml/lexer/context.{type Context}
import yum/yaml/token.{type BlockScalarStyle, type Chomp, type Token}

type Header {
  Header(style: BlockScalarStyle, chomp: Chomp, parent_indent: Int)
}

type Line {
  Line(indent: Int, content: String)
}

pub fn parser() -> Parser(YamlAST, Token, Context) {
  use header <- do(header_parser())
  use lines <- do(nibble.many(line_parser()))

  render(header, lines)
  |> yaml.String
  |> return
}

fn header_parser() -> Parser(Header, Token, Context) {
  use tok <- nibble.take_map("Expected a block scalar header")
  case tok {
    token.BlockScalarHeader(style:, chomp:, parent_indent:) ->
      Some(Header(style:, chomp:, parent_indent:))
    _ -> None
  }
}

fn line_parser() -> Parser(Line, Token, Context) {
  use tok <- nibble.take_map("Expected a block scalar line")
  case tok {
    token.BlockScalarLine(indent:, content:) -> Some(Line(indent:, content:))
    _ -> None
  }
}

fn render(header: Header, lines: List(Line)) -> String {
  let Header(style:, chomp:, parent_indent:) = header
  let normalized = normalize_lines(lines, parent_indent)
  let #(content_lines, trailing_empty_lines) = split_trailing_empty(normalized)

  let content = case style {
    token.Literal -> string.join(content_lines, "\n")
    token.Folded -> fold_lines(content_lines)
  }

  apply_chomp(content, content_lines, trailing_empty_lines, chomp)
}

fn normalize_lines(lines: List(Line), parent_indent: Int) -> List(String) {
  let content_indent = content_indent(lines, parent_indent)

  lines
  |> list.map(fn(line) { normalize_line(line, content_indent) })
}

fn content_indent(lines: List(Line), parent_indent: Int) -> Int {
  lines
  |> list.filter(fn(line) {
    case line {
      Line(content: "", ..) -> False
      Line(indent:, ..) -> indent > parent_indent
    }
  })
  |> list.map(fn(line) {
    let Line(indent:, ..) = line
    indent
  })
  |> min_indent(parent_indent + 1)
}

fn min_indent(indents: List(Int), default: Int) -> Int {
  case indents {
    [] -> default
    [first, ..rest] -> min_indent_loop(rest, first)
  }
}

fn min_indent_loop(indents: List(Int), current: Int) -> Int {
  case indents {
    [] -> current
    [indent, ..rest] -> min_indent_loop(rest, int.min(current, indent))
  }
}

fn normalize_line(line: Line, content_indent: Int) -> String {
  let Line(indent:, content:) = line

  case string.is_empty(content) {
    True -> ""
    False -> string.repeat(" ", int.max(0, indent - content_indent)) <> content
  }
}

fn split_trailing_empty(lines: List(String)) -> #(List(String), Int) {
  let #(trailing, content) = split_trailing_empty_loop(lines, 0, [])

  #(content, trailing)
}

fn split_trailing_empty_loop(
  lines: List(String),
  trailing: Int,
  content: List(String),
) -> #(Int, List(String)) {
  case lines {
    [] -> #(trailing, list.reverse(content))
    [line, ..rest] ->
      case string.is_empty(line), content {
        True, [] -> split_trailing_empty_loop(rest, trailing + 1, content)
        _, _ ->
          split_trailing_empty_loop(rest, 0, [
            line,
            ..empty_lines(trailing, content)
          ])
      }
  }
}

fn empty_lines(count: Int, content: List(String)) -> List(String) {
  case count {
    0 -> content
    _ -> empty_lines(count - 1, ["", ..content])
  }
}

fn fold_lines(lines: List(String)) -> String {
  fold_lines_loop(lines, [], 0)
  |> list.reverse()
  |> string.concat()
}

fn fold_lines_loop(
  lines: List(String),
  parts: List(String),
  empty_lines: Int,
) -> List(String) {
  case lines {
    [] -> parts
    [line, ..rest] ->
      case string.is_empty(line), parts {
        True, _ -> fold_lines_loop(rest, parts, empty_lines + 1)
        False, [] -> fold_lines_loop(rest, [line], 0)
        False, [_, ..] -> {
          let separator = case empty_lines {
            0 -> " "
            _ -> string.repeat("\n", empty_lines)
          }

          fold_lines_loop(rest, [line, separator, ..parts], 0)
        }
      }
  }
}

fn apply_chomp(
  content: String,
  content_lines: List(String),
  trailing_empty_lines: Int,
  chomp: Chomp,
) -> String {
  case chomp, content_lines, trailing_empty_lines {
    token.Strip, _, _ -> content
    token.Clip, [], 0 -> ""
    token.Clip, _, _ -> content <> "\n"
    token.Keep, [], 0 -> ""
    token.Keep, _, _ ->
      content <> "\n" <> string.repeat("\n", trailing_empty_lines)
  }
}
