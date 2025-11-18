///|
pub(all) struct BlockExpr {
  stmts : Array[Stmt]
} derive(Show, Eq)

///|
pub fn parse_block_expr(
  tokens : ArrayView[Token],
) -> (BlockExpr, ArrayView[Token]) raise ParseError {
  guard tokens is [{ kind: Bracket('{') }, .. rest] else {
    raise ParseError("block_expr: Unexpected token: \{tokens[0]}")
  }
  let stmts : Array[Stmt] = []
  loop rest {
    [{ kind: Bracket('}') }, .. rest] => return (BlockExpr::{ stmts, }, rest)
    tokens => {
      let (stmt, rest) = parse_stmt(tokens)
      stmts.push(stmt)
      continue rest
    }
  }
}
