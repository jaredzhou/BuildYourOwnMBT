///|
pub fn Context::atom_expr_to_knf(
  self : Context,
  atom_expr : @typecheck.AtomExpr,
) -> (Array[KnfStmt], KnfExpr) raise KnfTransformError {
  match atom_expr.kind {
    Int(value) => (Array::new(), KnfExpr::Int(value))
    Double(value) => (Array::new(), KnfExpr::Double(value))
    Bool(value) => (Array::new(), KnfExpr::Bool(value))
    String(value) => (Array::new(), KnfExpr::String(value))
    Ident(name) => {
      guard self.lookup_name(name) is Some((name, _)) else {
        raise KnfTransformError("name not found: \{name}")
      }
      (Array::new(), KnfExpr::Ident(name))
    }
    Unit => (Array::new(), KnfExpr::Unit)
    Paren(expr) => self.expr_to_knf(expr)
    Tuple(exprs) => {
      let (stmts, names) = self.array_expr_to_knf(exprs)
      (stmts, KnfExpr::TupleLiteral(names))
    }
    Array(exprs) => {
      let (stmts, names) = self.array_expr_to_knf(exprs)
      (stmts, KnfExpr::ArrayLiteral(self.typekind_to_knf(atom_expr.ty), names))
    }
    ArrayMake(size_expr, init_expr) => {
      let stmts = []
      let (size_stmt, size_knf_expr) = self.expr_to_knf(size_expr)
      stmts.append(size_stmt)
      let (init_stmt, init_knf_expr) = self.expr_to_knf(init_expr)
      stmts.append(init_stmt)
      let size_name = self.add_temp(self.typekind_to_knf(size_expr.ty))
      stmts.push(
        KnfStmt::Let(
          size_name,
          self.typekind_to_knf(size_expr.ty),
          size_knf_expr,
        ),
      )
      let init_name = self.add_temp(self.typekind_to_knf(init_expr.ty))
      stmts.push(
        KnfStmt::Let(
          init_name,
          self.typekind_to_knf(init_expr.ty),
          init_knf_expr,
        ),
      )
      (stmts, KnfExpr::ArrayMake(size_name, init_name))
    }
    StructConstruct(sc_expr) => {
      let stmts = []
      let fields = sc_expr.fields
        .map(field => {
          let (field_name, field_expr) = field
          let (field_stmt, field_knf_expr) = self.expr_to_knf(field_expr)
          stmts.append(field_stmt)
          let ty = self.typekind_to_knf(field_expr.ty)
          let name = self.add_temp(ty)
          (field_name, name, ty, field_knf_expr)
        })
        .map(field => {
          let (field_name, name, ty, field_knf_expr) = field
          stmts.push(KnfStmt::Let(name, ty, field_knf_expr))
          (field_name, name)
        })
      (stmts, KnfExpr::CreateStruct(sc_expr.name, fields))
    }
  }
}

///|
fn Context::array_expr_to_knf(
  self : Context,
  exprs : Array[@typecheck.Expr],
) -> (Array[KnfStmt], Array[Name]) raise KnfTransformError {
  let stmts = []
  let names = exprs.map(expr => {
    let (inner_stmt, knf_expr) = self.expr_to_knf(expr)
    stmts.append(inner_stmt)
    let name = self.expr_to_knf_name(
      knf_expr,
      self.typekind_to_knf(expr.ty),
      stmts,
    )
    name
  })
  (stmts, names)
}
