///|
pub fn Context::block_codegen(
  self : Self,
  block : @knf.KnfBlock,
) -> &@llvm.Value? raise {
  let current_func = self.builder.getInsertFunction()
  let block_bb = current_func.addBasicBlock()
  let after_bb = current_func.addBasicBlock()
  let _ = self.builder.createBr(block_bb)
  self.builder.setInsertPoint(block_bb)
  let value = match block.stmts.length() {
    0 => None
    n => {
      block.stmts[:n - 1].each(stmt => self.stmt_codegen(stmt))
      let last = block.stmts[n - 1]
      match last {
        ExprStmt(expr) => self.expr_codegen(expr)
        _ => {
          self.stmt_codegen(last)
          None
        }
      }
    }
  }
  let _ = self.builder.createBr(after_bb)
  self.builder.setInsertPoint(after_bb)
  value
}
