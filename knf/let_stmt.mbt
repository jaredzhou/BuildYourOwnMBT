///|
pub fn Context::let_stmt_to_knf(
  self : Context,
  let_stmt : @typecheck.LetStmt,
) -> Array[KnfStmt] raise KnfTransformError {
  let stmts = []
  let (expr_stmts, expr_knf) = self.expr_to_knf(let_stmt.expr)
  stmts.append(expr_stmts)
  stmts.append(
    self.bind_pattern_to_expr(
      let_stmt.pattern,
      self.typekind_to_knf(let_stmt.ty),
      expr_knf,
    ),
  )
  stmts
}

///|
fn Context::bind_pattern_to_expr(
  self : Context,
  pattern : @typecheck.Pattern,
  pattern_ty : Type,
  expr : KnfExpr,
) -> Array[KnfStmt] raise KnfTransformError {
  let stmts = []
  match pattern.kind {
    Wildcard => {
      stmts.push(KnfStmt::Let(Name::wildcard(), pattern_ty, expr))
      stmts
    }
    Ident(name) => {
      let name = self.add_new_name(name, pattern_ty)
      stmts.push(KnfStmt::Let(name, pattern_ty, expr))
      stmts
    }
    Tuple(patterns) => {
      guard pattern_ty is Tuple(types) && patterns.length() == types.length() else {
        raise KnfTransformError(
          "pattern type mismatch: \{pattern_ty} and \{pattern} and expr: \{expr}",
        )
      }
      let names = match expr {
        TupleLiteral(names) => names.map(name => KnfExpr::Ident(name))
        Ident(name) => {
          let ty = self.name_env.get_name_type(name).unwrap()
          guard ty is Tuple(types) else {
            raise KnfTransformError("name is not a tuple: \{name}")
          }
          types.mapi((i, _) => KnfExpr::TupleAccess(name, i))
        }
        _ => raise KnfTransformError("expr is not a tuple literal")
      }
      patterns.eachi((i, pattern) => {
        let pstmts = self.bind_pattern_to_expr(pattern, types[i], names[i])
        stmts.append(pstmts)
      })
      println("bind_pattern_to_expr stmts: \{stmts}")
      stmts
    }
  }
}
