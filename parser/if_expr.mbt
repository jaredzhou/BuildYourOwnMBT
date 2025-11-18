///|
pub(all) struct IfExpr {
  cond : Expr
  then_block : BlockExpr
  else_block : Either[IfExpr, BlockExpr]?
} derive(Show, Eq)

///|
pub fn parse_if_expr(
  tokens : ArrayView[Token],
) -> (IfExpr, ArrayView[Token]) raise ParseError {
  guard tokens is [{ kind: Keyword(If) }, .. rest] else {
    raise ParseError("1Unexpected token: \{tokens[0]}")
  }
  let (cond, rest) = parse_expr(rest)
  let (then_block, rest) = parse_block_expr(rest)
  let (else_block, rest) = if rest is [{ kind: Keyword(Else) }, .. rest] {
    match rest {
      [{ kind: Keyword(If) }, ..] => {
        let (if_expr, rest) = parse_if_expr(rest)
        (Some(Left(if_expr)), rest)
      }
      [{ kind: Bracket('{') }, ..] => {
        let (block_expr, rest) = parse_block_expr(rest)
        (Some(Right(block_expr)), rest)
      }
      _ => raise ParseError("2Unexpected token: \{rest[0]}")
    }
  } else {
    (None, rest)
  }
  (IfExpr::{ cond, then_block, else_block }, rest)
}
