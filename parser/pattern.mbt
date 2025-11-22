///|
pub(all) struct Pattern {
  kind : PatternKind
} derive(Show, Eq)

///|
pub fn Pattern::new(kind : PatternKind) -> Pattern {
  Pattern::{ kind, }
}

///|
pub(all) enum PatternKind {
  Wildcard
  Ident(String)
  Tuple(Array[Pattern])
} derive(Show, Eq)

///|
pub fn parse_pattern(
  tokens : ArrayView[Token],
) -> (Pattern, ArrayView[Token]) raise ParseError {
  match tokens {
    [{ kind: @lexer.Wildcard }, .. rest] =>
      (Pattern::new(PatternKind::Wildcard), rest)
    [{ kind: @lexer.Lower(name) }, .. rest] =>
      (Pattern::new(PatternKind::Ident(name)), rest)
    [{ kind: Bracket('(') }, ..] as rest => {
      let (patterns, rest) = parse_list_pattern(rest)
      (Pattern::new(PatternKind::Tuple(patterns)), rest)
    }
    _ => raise ParseError("pattern Unexpected token: \{tokens[0]}")
  }
}

///|
pub fn parse_list_pattern(
  tokens : ArrayView[Token],
) -> (Array[Pattern], ArrayView[Token]) raise ParseError {
  guard tokens is [{ kind: lb }, .. tokens] && lb == Bracket('(') else {
    raise ParseError("list pattern Unexpected token: \{tokens[0]}")
  }
  let patterns : Array[Pattern] = []
  loop tokens {
    // 遇到右括号，结束解析并返回结果
    [{ kind: Bracket(')') }, .. rest] => (patterns, rest)

    // 解析模式, 如果有逗号， 跳过逗号
    // 处理逗号后的情况：支持尾随逗号，不允许连续逗号，开头逗号，多个尾随逗号
    // 开头是逗号， 连续逗号， 多个尾随逗号，都会执行到parse_pattern， 然后报错
    //一个尾随逗号或者没有尾随逗号都会正常解析
    tokens => {
      let (pattern, rest) = parse_pattern(tokens)
      patterns.push(pattern)
      //一个pattern后面要么是",",要么是")" 不能是其他的
      match rest {
        [{ kind: Symbol(",") }, .. rest] => continue rest
        [{ kind: Bracket(')') }, ..] => continue rest
        _ => raise ParseError("list pattern Unexpected token: \{rest[0]}")
      }
    }
  }
}
