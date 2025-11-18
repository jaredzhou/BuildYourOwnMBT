///|
pub(all) struct BlockExpr {
  stmts : Array[Stmt]
  ty : TypeKind
} derive(Show)

///|
pub fn Context::check_block_expr(
  self : Context,
  block_expr : @parser.BlockExpr,
) -> BlockExpr raise TypeCheckError {
  self.enter_scope()
  let stmts = block_expr.stmts.map(stmt => self.check_stmt(stmt))
  let ty = if stmts.last() is Some(stmt) {
    match stmt.kind {
      StmtKind::ExprStmt(expr) => expr.ty
      StmtKind::ReturnStmt(Some(expr)) => expr.ty
      _ => Unit
    }
  } else {
    Unit
  }
  let block_expr = BlockExpr::{ stmts, ty }
  self.exit_scope()
  block_expr
}
