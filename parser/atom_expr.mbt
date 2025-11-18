///|
pub(all) struct AtomExpr {
  kind : AtomExprKind
} derive(Show, Eq)

///|
pub fn AtomExpr::new(kind : AtomExprKind) -> AtomExpr {
  AtomExpr::{ kind, }
}

///|
pub(all) enum AtomExprKind {
  Int(Int) // 1, 42, etc
  Double(Double) // 1.0, 3.14, etc
  Bool(Bool) // true | false
  String(String) // "hello", etc
  Ident(String) // var
  Unit // ()
  Paren(Expr) // (expr)
  Tuple(Array[Expr]) // (expr, expr, ...)
  Array(Array[Expr]) // [expr, expr, ...]
  ArrayMake(Expr, Expr) // Array::make(size, init)
  StructConstruct(StructConstructExpr) // StructName::{ field: expr, ... }
} derive(Show, Eq)

///|
pub fn parse_atom_expr(
  tokens : ArrayView[Token],
) -> (AtomExpr, ArrayView[Token]) raise ParseError {
  match tokens {
    [{ kind: Int(value) }, .. rest_tokens] =>
      (AtomExpr::new(AtomExprKind::Int(value)), rest_tokens)
    [{ kind: Double(value) }, .. rest_tokens] =>
      (AtomExpr::new(AtomExprKind::Double(value)), rest_tokens)
    [{ kind: Bool(value) }, .. rest_tokens] =>
      (AtomExpr::new(AtomExprKind::Bool(value)), rest_tokens)
    [{ kind: String(value) }, .. rest_tokens] =>
      (AtomExpr::new(AtomExprKind::String(value)), rest_tokens)
    [{ kind: Lower(value) }, .. rest_tokens] =>
      (AtomExpr::new(AtomExprKind::Ident(value)), rest_tokens)
    [{ kind: Bracket('(') }, ..] => {
      let (exprs, rest) = parse_list_expr(Bracket('('), Bracket(')'), tokens)
      match exprs.length() {
        0 => (AtomExpr::new(AtomExprKind::Unit), rest)
        1 => (AtomExpr::new(AtomExprKind::Paren(exprs[0])), rest)
        _ => (AtomExpr::new(AtomExprKind::Tuple(exprs)), rest)
      }
    }
    [{ kind: Upper(ident) }, ..] =>
      match ident {
        "Array" => parse_array_make_expr(tokens)
        _ => parse_struct_construct(tokens)
      }
    [{ kind: Bracket('[') }, ..] => {
      let (exprs, rest) = parse_list_expr(Bracket('['), Bracket(']'), tokens)
      (AtomExpr::new(AtomExprKind::Array(exprs)), rest)
    }
    rest => raise ParseError("Unexpected token: " + rest.to_string())
  }
}

///|
/// 
fn parse_array_make_expr(
  tokens : ArrayView[Token],
) -> (AtomExpr, ArrayView[Token]) raise ParseError {
  guard tokens
    is [
      { kind: Upper("Array") },
      { kind: Symbol("::") },
      { kind: Lower("make") },
      { kind: Bracket('(') },
      .. rest,
    ] else {
    raise ParseError("Unexpected token: \{tokens[0]}")
  }
  let (size, rest) = parse_expr(rest)
  guard rest is [{ kind: Symbol(",") }, .. rest] else {
    raise ParseError("Unexpected token: \{rest[0]}")
  }
  let (init, rest) = parse_expr(rest)
  guard rest is [{ kind: Bracket(')') }, .. rest] else {
    raise ParseError("Unexpected token: \{rest[0]}")
  }
  (AtomExpr::new(AtomExprKind::ArrayMake(size, init)), rest)
}

///|
/// 解析数组或元组表达式
/// 
/// 处理逻辑：
/// 1. 支持数组字面量：`[expr1, expr2, ...]`
/// 2. 支持元组字面量：`(expr1, expr2, ...)`
/// 3. 支持尾随逗号：`[1, 2, 3,]` 或 `(a, b,)`
/// 4. 不允许连续逗号：`[1, , 2]`， 开头逗号 `[,1,2]`, 多个尾随逗号 `[1, 2, 3, ,]`
/// 
/// 参数：
/// - lbracket: 左括号字符 ('[' 或 '(')
/// - rbracket: 右括号字符 (']' 或 ')')
/// - tokens: 待解析的token序列
/// 
/// 返回：解析出的表达式数组和剩余的token
pub fn parse_list_expr(
  lbracket : @lexer.TokenKind,
  rbracket : @lexer.TokenKind,
  tokens : ArrayView[Token],
) -> (Array[Expr], ArrayView[Token]) raise ParseError {
  guard tokens is [{ kind: lb }, .. tokens] && lb == lbracket else {
    raise ParseError("Unexpected token: \{tokens[0]}")
  }
  let exprs : Array[Expr] = []
  loop tokens {
    // 遇到右括号，结束解析并返回结果
    [{ kind: rb }, .. rest] if rb == rbracket => (exprs, rest)

    // 解析普通表达式, 如果有逗号， 跳过逗号
    // 处理逗号后的情况：支持尾随逗号，不允许连续逗号，开头逗号，多个尾随逗号
    // 开头是逗号， 连续逗号， 多个尾随逗号，都会执行到parse_expr， 然后报错
    //一个尾随逗号或者没有尾随逗号都会正常解析
    tokens => {
      let (expr, rest) = parse_expr(tokens)
      exprs.push(expr)
      //一个expr后面要么是",",要么是"}" 不能是其他的
      match rest {
        [{ kind: Symbol(",") }, .. rest] => continue rest
        [{ kind: rb }, ..] if rb == rbracket => continue rest
        _ => raise ParseError("Unexpected token: \{rest[0]}")
      }
    }
  }
}
