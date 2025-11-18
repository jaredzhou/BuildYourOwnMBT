///|
pub(all) struct WhileStmt {
  cond : Expr
  body : BlockExpr
} derive(Show, Eq)

///|
pub fn parse_while_stmt(
  tokens : ArrayView[Token],
) -> (WhileStmt, ArrayView[Token]) raise ParseError {
  guard tokens is [{ kind: Keyword(While) }, .. rest] else {
    raise ParseError("while_stmt: Unexpected token: \{tokens[0]}")
  }
  let (cond, rest) = parse_expr(rest)
  let (block_expr, rest) = parse_block_expr(rest)
  (WhileStmt::{ cond, body: block_expr }, rest)
}
