///|
pub(all) struct AssignStmt {
  left_value : LeftValue
  op : AssignOp
  expr : Expr
} derive(Show, Eq)

///|
pub(all) enum AssignOp {
  Assign // =
  PlusAssign // +=
  MinusAssign // -=
  MultAssign // *=
  DivAssign // /=
  ModAssign // %=
} derive(Show, Eq)

///|
fn AssignOp::from_tok_assign_op(op : @lexer.AssignOp) -> AssignOp {
  match op {
    Assign => Assign
    PlusAssign => PlusAssign
    MinusAssign => MinusAssign
    MultAssign => MultAssign
    DivAssign => DivAssign
    ModAssign => ModAssign
  }
}

///|
pub fn parse_assign_stmt(
  tokens : ArrayView[Token],
) -> (AssignStmt, ArrayView[Token]) raise ParseError {
  let (left_value, rest) = parse_left_value(tokens)
  guard rest is [{ kind: AssignOp(op) }, .. rest] else {
    raise ParseError("assgin Unexpected token: \{rest[0]}")
  }
  let (expr, rest) = parse_expr(rest)
  guard rest is [{ kind: Symbol(";") }, .. rest] else {
    raise ParseError("assign Unexpected token: \{rest[0]}")
  }
  (AssignStmt::{ left_value, op: AssignOp::from_tok_assign_op(op), expr }, rest)
}
