///|
pub(all) struct TopLet {
  name : String
  ty : Type?
  expr : Expr
} derive(Show, Eq)

///|
pub fn parse_top_let(
  tokens : ArrayView[Token],
) -> (TopLet, ArrayView[Token]) raise ParseError {
  guard tokens is [{ kind: Keyword(Let) }, { kind: Lower(name) }, .. rest] else {
    raise ParseError("top let Unexpected token: \{tokens[0]}")
  }
  let (ty, rest) = if rest is [{ kind: Symbol(":") }, .. rest] {
    let (ty, rest) = parse_type(rest)
    (Some(ty), rest)
  } else {
    (None, rest)
  }
  guard rest is [{ kind: AssignOp(Assign) }, .. rest] else {
    raise ParseError("top let Unexpected token: \{rest[0]}")
  }
  let (expr, rest) = parse_expr(rest)
  guard rest is [{ kind: Symbol(";") }, .. rest] else {
    raise ParseError("top let Unexpected token: \{rest[0]}")
  }
  (TopLet::{ name, ty, expr }, rest)
}
