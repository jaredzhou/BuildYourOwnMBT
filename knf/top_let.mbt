///|
pub(all) struct KnfTopLet {
  name : Name
  ty : Type
  expr : KnfExpr
}

///|
pub fn Context::top_let_to_knf(
  self : Context,
  top_let : @typecheck.TopLet,
) -> KnfTopLet raise KnfTransformError {
  let (expr_stmts, expr_knf) = self.expr_to_knf(top_let.expr)
  let stmts = []
  stmts.append(expr_stmts)
  let ty = self.typekind_to_knf(top_let.ty)
  let name = self.add_new_name(top_let.name, ty)
  stmts.push(Let(name, ty, expr_knf))
  guard self.globals.get(top_let.name) is None else {
    raise KnfTransformError(
      "Duplicate global variable declaration: \{top_let.name}",
    )
  }
  self.globals.set(top_let.name, ty)
  KnfTopLet::{ name, ty, expr: expr_knf }
}

///|
pub impl Show for KnfTopLet with output(self, logger) {
  let { name, ty, expr } = self
  logger.write_string("let \{name} : \{ty} = \{expr};")
}
