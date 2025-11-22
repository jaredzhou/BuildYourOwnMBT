///|
pub(all) struct LetStmt {
  pattern : Pattern
  ty : Type?
  expr : Expr
} derive(Show, Eq)

///|
pub fn parse_let_stmt(
  tokens : ArrayView[Token],
) -> (LetStmt, ArrayView[Token]) raise ParseError {
  guard tokens is [{ kind: Keyword(Let) }, .. rest] else {
    raise ParseError("let stmt Unexpected token: \{tokens[0]}")
  }
  let (pattern, rest) = parse_pattern(rest)
  let (ty, rest) = if rest is [{ kind: Symbol(":") }, .. rest] {
    let (ty, rest_tokens) = parse_type(rest)
    (Some(ty), rest_tokens)
  } else {
    (None, rest)
  }
  guard rest is [{ kind: AssignOp(Assign) }, .. rest] else {
    raise ParseError("let stmt Unexpected token: \{rest[0]}")
  }
  let (expr, rest) = parse_expr(rest)
  guard rest is [{ kind: Symbol(";") }, .. rest] else {
    raise ParseError("Unexpected token: \{rest[0]}")
  }
  (LetStmt::{ pattern, ty, expr }, rest)
}
