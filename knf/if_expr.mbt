///|
pub fn Context::if_expr_to_knf(
  self : Context,
  if_expr : @typecheck.IfExpr,
) -> (Array[KnfStmt], KnfExpr) raise KnfTransformError {
  let stmts = []
  let (cond_stmts, cond_knf_expr) = self.expr_to_knf(if_expr.cond)
  stmts.append(cond_stmts)
  let then_knf_block = self.block_expr_to_knf(if_expr.then_block)
  let else_knf_block = match if_expr.else_block {
    Some(Left(else_if_expr)) => {
      let (nested_stmts, nested_if_knf) = self.if_expr_to_knf(else_if_expr)
      stmts.append(nested_stmts)
      guard nested_if_knf is KnfExpr::If(_, then_block, _) else {
        raise KnfTransformError("nested if expression must be a if expression")
      }
      KnfBlock::{ stmts: [KnfStmt::ExprStmt(nested_if_knf)], ty: then_block.ty }
    }
    Some(Right(else_block_expr)) => self.block_expr_to_knf(else_block_expr)
    None => KnfBlock::{ stmts: [], ty: Unit }
  }
  (stmts, KnfExpr::If(cond_knf_expr, then_knf_block, else_knf_block))
}
