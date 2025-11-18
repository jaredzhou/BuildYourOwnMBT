///|
pub(all) struct LetMutStmt {
  name : String
  ty : Type?
  expr : Expr
} derive(Show, Eq)

///|
pub fn parse_let_mut_stmt(
  tokens : ArrayView[Token],
) -> (LetMutStmt, ArrayView[Token]) raise ParseError {
  guard tokens is [{ kind: Keyword(Let) }, { kind: Keyword(Mut) }, .. rest] else {
    raise ParseError("Expected 'let mut' but found: \{tokens[0]}")
  }
  guard rest is [{ kind: Lower(name) }, .. rest] else {
    raise ParseError(
      "Expected identifier after 'let mut' but found: \{rest[0]}",
    )
  }
  let (ty, rest) = if rest is [{ kind: Symbol(":") }, .. rest] {
    let (ty, rest_tokens) = parse_type(rest)
    (Some(ty), rest_tokens)
  } else {
    (None, rest)
  }
  guard rest is [{ kind: AssignOp(Assign) }, .. rest] else {
    raise ParseError("Expected '=' but found: \{rest[0]}")
  }
  let (expr, rest) = parse_expr(rest)
  guard rest is [{ kind: Symbol(";") }, .. rest] else {
    raise ParseError("Expected ';' but found: \{rest[0]}")
  }
  (LetMutStmt::{ name, ty, expr }, rest)
}
