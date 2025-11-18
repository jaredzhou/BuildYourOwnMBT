///|
pub fn Context::while_stmt_to_knf(
  self : Context,
  while_stmt : @typecheck.WhileStmt,
) -> Array[KnfStmt] raise KnfTransformError {
  let (cond_stmts, cond_knf_expr) = self.expr_to_knf(while_stmt.cond)
  cond_stmts.push(ExprStmt(cond_knf_expr))
  let cond_knf_block = KnfBlock::{ stmts: cond_stmts, ty: Bool }
  let body_knf_block = self.block_expr_to_knf(while_stmt.body)
  [While(cond_knf_block, body_knf_block)]
}
