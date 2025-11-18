///|
pub(all) suberror TokenizeError String derive(Show)

///|
pub(all) enum Keyword {
  Fn
  Struct
  Let
  Mut
  If
  Else
  While
  For
  Return
} derive(Show, Eq)

///|
pub(all) enum BinaryOp {
  Add // +
  Sub // -
  Mul // *
  Div // /
  Mod // %
  ShiftLeft // <<
  ShiftRight // >>
  Eq // ==
  NE // !=
  LT // <
  GT // >
  LE // <=
  GE // >=
  And // &&
  Or // ||
  BitAnd // &
  BitOr // |
} derive(Eq)

///|
pub impl Show for BinaryOp with output(self, logger) {
  let s = match self {
    Add => "+"
    Sub => "-"
    Mul => "*"
    Div => "/"
    Mod => "%"
    ShiftLeft => "<<"
    ShiftRight => ">>"
    Eq => "=="
    NE => "!="
    LT => "<"
    GT => ">"
    LE => "<="
    GE => ">="
    And => "&&"
    Or => "||"
    BitAnd => "&"
    BitOr => "|"
  }
  logger.write_string(s)
}

///|
pub(all) enum AssignOp {
  Assign // =
  PlusAssign // +=
  MinusAssign // -=
  MultAssign // *=
  DivAssign // /=
  ModAssign // %=
} derive(Show, Eq, ToJson)

///|
pub struct Token {
  kind : TokenKind
  // other info
} derive(Show, Eq)

///|
pub fn Token::new(kind : TokenKind) -> Token {
  Token::{ kind, }
}

///|
pub(all) enum TokenKind {
  Bool(Bool) // true, false
  Int(Int) // 1, 42, -100
  Double(Double)
  String(String) // "hello", "world"
  Keyword(Keyword)
  Upper(String)
  Lower(String)
  BinaryOp(BinaryOp) // +, -, *, /, %, =, ==, !=, <, >, <=, >=, &&, ||
  AssignOp(AssignOp) // =, +=, -=, *=, /=, %=
  Not // !
  Bracket(Char) // (, ), [, ], {, }
  Symbol(String) // . , ; : :: -> => 
  Wildcard // _
  EOF
} derive(Show, Eq)

///|
fn skip_comment(s : StringView) -> StringView {
  match s {
    [] => s
    ['\n', .. rest] => rest
    [_, .. rest] => skip_comment(rest)
  }
}

///|
fn collect_identifier(s : StringView, acc : String) -> (String, StringView) {
  match s {
    [] => (acc, s)
    [c, .. rest] =>
      if (c >= 'a' && c <= 'z') ||
        (c >= 'A' && c <= 'Z') ||
        (c >= '0' && c <= '9') ||
        c == '_' {
        collect_identifier(rest, acc + c.to_string())
      } else {
        (acc, s)
      }
  }
}

///|
fn collect_number(s : StringView, acc : String) -> (String, StringView, Bool) {
  match s {
    [] => (acc, s, acc.contains("."))
    [c, .. rest] =>
      if (c >= '0' && c <= '9') || c == '.' {
        collect_number(rest, acc + c.to_string())
      } else {
        (acc, s, acc.contains("."))
      }
  }
}

///|
fn collect_string(s : StringView, acc : String) -> (String, StringView) {
  match s {
    [] => (acc, s) // 到达文件结尾，返回当前内容
    ['"', .. rest] => (acc, rest) // 遇到结束引号，返回字符串内容和剩余部分
    [c, .. rest] => collect_string(rest, acc + c.to_string()) // 继续收集字符
  }
}

///|
pub fn tokenize(code : String) -> Array[Token] {
  let tokens = Array::new()
  let s = code[:]

  // Process characters one by one using loop with direct pattern matching
  let _ = loop s {
    [] => {
      tokens.push(Token::new(EOF))
      break
    }
    [' ' | '\n' | '\t' | '\r', .. rest] => continue rest // Skip whitespace

    // 注释处理：单行注释 //
    [.. "//", .. rest] => continue skip_comment(rest)

    // 字符串处理：双引号字符串
    ['"', .. rest] => {
      let (str_content, rest_after_str) = collect_string(rest, "")
      tokens.push(Token::new(String(str_content)))
      continue rest_after_str
    }

    // 最长匹配优先：多字符操作符和符号
    [.. "::", .. rest] => {
      tokens.push(Token::new(Symbol("::")))
      continue rest
    }
    [.. "=>", .. rest] => {
      tokens.push(Token::new(Symbol("=>")))
      continue rest
    }
    [.. "->", .. rest] => {
      tokens.push(Token::new(Symbol("->")))
      continue rest
    }
    [.. "==", .. rest] => {
      tokens.push(Token::new(BinaryOp(Eq)))
      continue rest
    }
    [.. "!=", .. rest] => {
      tokens.push(Token::new(BinaryOp(NE)))
      continue rest
    }
    [.. "<=", .. rest] => {
      tokens.push(Token::new(BinaryOp(LE)))
      continue rest
    }
    [.. ">=", .. rest] => {
      tokens.push(Token::new(BinaryOp(GE)))
      continue rest
    }
    [.. "<<", .. rest] => {
      tokens.push(Token::new(BinaryOp(ShiftLeft)))
      continue rest
    }
    [.. ">>", .. rest] => {
      tokens.push(Token::new(BinaryOp(ShiftRight)))
      continue rest
    }
    [.. "&&", .. rest] => {
      tokens.push(Token::new(BinaryOp(And)))
      continue rest
    }
    [.. "||", .. rest] => {
      tokens.push(Token::new(BinaryOp(Or)))
      continue rest
    }
    [.. "+=", .. rest] => {
      tokens.push(Token::new(AssignOp(PlusAssign)))
      continue rest
    }
    [.. "-=", .. rest] => {
      tokens.push(Token::new(AssignOp(MinusAssign)))
      continue rest
    }
    [.. "*=", .. rest] => {
      tokens.push(Token::new(AssignOp(MultAssign)))
      continue rest
    }
    [.. "/=", .. rest] => {
      tokens.push(Token::new(AssignOp(DivAssign)))
      continue rest
    }
    [.. "%=", .. rest] => {
      tokens.push(Token::new(AssignOp(ModAssign)))
      continue rest
    }

    // 单字符操作符和符号
    [.. "+", .. rest] => {
      tokens.push(Token::new(BinaryOp(Add)))
      continue rest
    }
    [.. "-", .. rest] => {
      tokens.push(Token::new(BinaryOp(Sub)))
      continue rest
    }
    [.. "*", .. rest] => {
      tokens.push(Token::new(BinaryOp(Mul)))
      continue rest
    }
    [.. "/", .. rest] => {
      tokens.push(Token::new(BinaryOp(Div)))
      continue rest
    }
    [.. "%", .. rest] => {
      tokens.push(Token::new(BinaryOp(Mod)))
      continue rest
    }
    [.. "<", .. rest] => {
      tokens.push(Token::new(BinaryOp(LT)))
      continue rest
    }
    [.. ">", .. rest] => {
      tokens.push(Token::new(BinaryOp(GT)))
      continue rest
    }
    [.. "&", .. rest] => {
      tokens.push(Token::new(BinaryOp(BitAnd)))
      continue rest
    }
    [.. "|", .. rest] => {
      tokens.push(Token::new(BinaryOp(BitOr)))
      continue rest
    }
    [.. "=", .. rest] => {
      tokens.push(Token::new(AssignOp(Assign)))
      continue rest
    }
    [.. "!", .. rest] => {
      tokens.push(Token::new(Not))
      continue rest
    }

    // 括号 (Bracket)
    ['(', .. rest] => {
      tokens.push(Token::new(Bracket('(')))
      continue rest
    }
    [')', .. rest] => {
      tokens.push(Token::new(Bracket(')')))
      continue rest
    }
    ['{', .. rest] => {
      tokens.push(Token::new(Bracket('{')))
      continue rest
    }
    ['}', .. rest] => {
      tokens.push(Token::new(Bracket('}')))
      continue rest
    }
    ['[', .. rest] => {
      tokens.push(Token::new(Bracket('[')))
      continue rest
    }
    [']', .. rest] => {
      tokens.push(Token::new(Bracket(']')))
      continue rest
    }

    // 单字符符号
    [':', .. rest] => {
      tokens.push(Token::new(Symbol(":")))
      continue rest
    }
    [';', .. rest] => {
      tokens.push(Token::new(Symbol(";")))
      continue rest
    }
    [',', .. rest] => {
      tokens.push(Token::new(Symbol(",")))
      continue rest
    }
    ['.', .. rest] => {
      tokens.push(Token::new(Symbol(".")))
      continue rest
    }

    // a-z, _ 开头的标识符和关键字
    ['a'..='z' | '_', ..] as s => {
      let (ident, rest_after_ident) = collect_identifier(s, "")
      match ident {
        "fn" => tokens.push(Token::new(Keyword(Fn)))
        "struct" => tokens.push(Token::new(Keyword(Struct)))
        "let" => tokens.push(Token::new(Keyword(Let)))
        "mut" => tokens.push(Token::new(Keyword(Mut)))
        "if" => tokens.push(Token::new(Keyword(If)))
        "else" => tokens.push(Token::new(Keyword(Else)))
        "while" => tokens.push(Token::new(Keyword(While)))
        "for" => tokens.push(Token::new(Keyword(For)))
        "return" => tokens.push(Token::new(Keyword(Return)))
        "_" => tokens.push(Token::new(Wildcard))
        "true" => tokens.push(Token::new(Bool(true)))
        "false" => tokens.push(Token::new(Bool(false)))
        _ => tokens.push(Token::new(Lower(ident)))
      }
      continue rest_after_ident
    }
    ['A'..='Z', ..] as s => {
      let (ident, rest_after_ident) = collect_identifier(s, "")
      tokens.push(Token::new(Upper(ident)))
      continue rest_after_ident
    }
    ['0'..='9', ..] as s => {
      let (num_str, rest_after_num, is_double) = collect_number(s, "")
      try {
        if is_double {
          let double_val = @strconv.parse_double(num_str)
          tokens.push(Token::new(Double(double_val)))
        } else {
          let int_val = @strconv.parse_int(num_str)
          tokens.push(Token::new(Int(int_val)))
        }
      } catch {
        // 解析失败时创建默认 token
        _ => tokens.push(Token::new(Int(0)))
      }
      continue rest_after_num
    }
    rest =>
      // Unknown character - skip
      continue rest
  }
  tokens
}
