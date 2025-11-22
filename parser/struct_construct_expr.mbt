///|
pub(all) struct StructConstructExpr {
  name : String
  fields : Array[(String, Expr)]
} derive(Show, Eq)

///|
pub fn parse_struct_construct(
  tokens : ArrayView[Token],
) -> (AtomExpr, ArrayView[Token]) raise ParseError {
  guard tokens
    is [
      { kind: Upper(name) },
      { kind: Symbol("::") },
      { kind: Bracket('{') },
      .. tokens,
    ] else {
    raise ParseError("Expected struct name and '::{")
  }
  let fields : Array[(String, Expr)] = []
  loop tokens {
    [{ kind: Bracket('}') }, .. rest] =>
      (
        AtomExpr::new(
          AtomExprKind::StructConstruct(StructConstructExpr::{ name, fields }),
        ),
        rest,
      )
    tokens => {
      guard tokens is [{ kind: Lower(name) }, { kind: Symbol(":") }, .. rest] else {
        raise ParseError("Expected field name, ':' and expr")
      }
      let (expr, rest) = parse_expr(rest)
      fields.push((name, expr))
      //一个field后面要么是",",要么是"}" 不能是其他的
      match rest {
        [{ kind: Symbol(",") }, .. rest] => continue rest
        [{ kind: Bracket('}') }, ..] => continue rest
        _ => raise ParseError("struct construct Unexpected token: \{rest[0]}")
      }
    }
  }
}
