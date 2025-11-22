///|
pub(all) struct KnfBlock {
  ty : Type
  stmts : Array[KnfStmt]
}

///|
pub fn Context::block_expr_to_knf(
  self : Context,
  expr : @typecheck.BlockExpr,
) -> KnfBlock raise KnfTransformError {
  let stmts = expr.stmts.map(stmt => self.stmt_to_knf(stmt)).flatten()
  let ty = self.typekind_to_knf(expr.ty)
  // println("block_expr_to_knf stmts: \{stmts}")
  KnfBlock::{ ty, stmts }
}

///|
pub fn KnfBlock::nested_to_string(self : KnfBlock) -> String {
  let sb = StringBuilder::new()
  sb.write_string("{")
  for stmt in self.stmts {
    sb.write_string(stmt.to_string(ident=0))
    sb.write_string(" ")
  }
  sb.write_string("}")
  sb.to_string()
}

///|
pub impl Show for KnfBlock with output(self, logger) {
  logger.write_string(self.nested_to_string())
}
