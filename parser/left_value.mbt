///|
pub(all) struct LeftValue {
  kind : LeftValueKind
} derive(Show, Eq)

///|
pub fn LeftValue::new(kind : LeftValueKind) -> LeftValue {
  LeftValue::{ kind, }
}

///|
pub(all) enum LeftValueKind {
  Ident(String)
  ArrayAccess(LeftValue, Expr)
  FieldAccess(LeftValue, String)
} derive(Show, Eq)

///|
pub fn parse_left_value(
  tokens : ArrayView[Token],
) -> (LeftValue, ArrayView[Token]) raise ParseError {
  guard tokens is [{ kind: Lower(name) }, .. rest_tokens] else {
    raise ParseError("left value Unexpected token: \{tokens[0]}")
  }
  let mut left_value = LeftValue::new(LeftValueKind::Ident(name))
  loop rest_tokens {
    [{ kind: Bracket('[') }, .. rest] => {
      let (index_expr, rest) = parse_expr(rest)
      left_value = LeftValue::new(
        LeftValueKind::ArrayAccess(left_value, index_expr),
      )
      guard rest is [{ kind: Bracket(']') }, .. rest] else {
        raise ParseError("left value Unexpected token: \{rest[0]}")
      }
      continue rest
    }
    [{ kind: Symbol(".") }, .. rest] => {
      guard rest is [{ kind: Lower(field) }, .. rest] else {
        raise ParseError("left value Unexpected token: \{rest[0]}")
      }
      left_value = LeftValue::new(LeftValueKind::FieldAccess(left_value, field))
      continue rest
    }
    tokens => return (left_value, tokens)
  }
}
