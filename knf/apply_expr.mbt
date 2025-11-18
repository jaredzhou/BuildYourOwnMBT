///|
pub fn Context::apply_expr_to_knf(
  self : Context,
  apply_expr : @typecheck.ApplyExpr,
) -> (Array[KnfStmt], KnfExpr) raise KnfTransformError {
  match apply_expr.kind {
    AtomExpr(atom_expr) => self.atom_expr_to_knf(atom_expr)
    ArrayAccess(apply_expr, index_expr) => {
      let (stmts, apply_knf) = self.apply_expr_to_knf(apply_expr)
      let (index_stmts, index_knf) = self.expr_to_knf(index_expr)
      stmts.append(index_stmts)
      let apply_name = self.expr_to_knf_name(
        apply_knf,
        self.typekind_to_knf(apply_expr.ty),
        stmts,
      )
      let index_name = self.expr_to_knf_name(
        index_knf,
        self.typekind_to_knf(index_expr.ty),
        stmts,
      )
      (stmts, KnfExpr::ArrayAccess(apply_name, index_name))
    }
    FieldAccess(apply_expr, field) => {
      let (stmts, apply_knf) = self.apply_expr_to_knf(apply_expr)
      let apply_name = self.expr_to_knf_name(
        apply_knf,
        self.typekind_to_knf(apply_expr.ty),
        stmts,
      )
      (stmts, KnfExpr::FieldAccess(apply_name, field))
    }
    Call(apply_expr, args) => {
      let (stmts, apply_knf) = self.apply_expr_to_knf(apply_expr)
      let apply_name = self.expr_to_knf_name(
        apply_knf,
        self.typekind_to_knf(apply_expr.ty),
        stmts,
      )
      let (args_stmts, args_names) = self.array_expr_to_knf(args)
      stmts.append(args_stmts)
      (stmts, KnfExpr::Call(apply_name, args_names))
    }
  }
}
