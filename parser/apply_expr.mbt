///|
pub(all) struct ApplyExpr {
  kind : ApplyExprKind
} derive(Show, Eq)

///|
pub fn ApplyExpr::new(kind : ApplyExprKind) -> ApplyExpr {
  return { kind, }
}

///|
pub(all) enum ApplyExprKind {
  AtomExpr(AtomExpr)
  ArrayAccess(ApplyExpr, Expr)
  FieldAccess(ApplyExpr, String)
  Call(ApplyExpr, Array[Expr])
} derive(Show, Eq)

///|
pub fn parse_apply_expr(
  tokens : ArrayView[Token],
) -> (ApplyExpr, ArrayView[Token]) raise ParseError {
  let (atom_expr, tokens) = parse_atom_expr(tokens)
  let mut apply_expr = ApplyExpr::new(ApplyExprKind::AtomExpr(atom_expr))
  loop tokens {
    [{ kind: Bracket('[') }, .. rest] => {
      let (index_expr, rest) = parse_expr(rest)
      apply_expr = ApplyExpr::new(
        ApplyExprKind::ArrayAccess(apply_expr, index_expr),
      )
      guard rest is [{ kind: Bracket(']') }, .. rest] else {
        raise ParseError("Unexpected token: \{rest[0]}")
      }
      continue rest
    }
    [{ kind: Bracket('(') }, ..] as rest => {
      let (args, rest) = parse_list_expr(Bracket('('), Bracket(')'), rest)
      apply_expr = ApplyExpr::new(ApplyExprKind::Call(apply_expr, args))
      continue rest
    }
    [{ kind: Symbol(".") }, .. rest] => {
      guard rest is [{ kind: Lower(field) }, .. rest] else {
        raise ParseError("Unexpected token: \{rest[0]}")
      }
      apply_expr = ApplyExpr::new(ApplyExprKind::FieldAccess(apply_expr, field))
      continue rest
    }
    tokens => return (apply_expr, tokens)
  }
}
