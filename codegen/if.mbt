///|
pub fn Context::if_codegen(
  self : Self,
  cond : @knf.KnfExpr,
  then_block : @knf.KnfBlock,
  else_block : @knf.KnfBlock,
) -> &@llvm.Value? raise {
  let current_func = self.builder.getInsertFunction()
  let then_bb = current_func.addBasicBlock()
  let else_bb = current_func.addBasicBlock()
  let merge_bb = current_func.addBasicBlock()
  let mut need_merge = false
  let cond_value = self.expr_codegen(cond)
  guard cond_value is Some(cond_value) else {
    raise CodegenError("cond_value is None")
  }
  let _ = self.builder.createCondBr(cond_value, then_bb, else_bb)
  self.builder.setInsertPoint(then_bb)
  let then_value : &@llvm.Value? = match then_block.stmts.length() {
    0 => None
    n => {
      then_block.stmts[:n - 1].each(stmt => self.stmt_codegen(stmt))
      let last = then_block.stmts[n - 1]
      match last {
        ExprStmt(expr) => self.expr_codegen(expr)
        _ => {
          self.stmt_codegen(last)
          None
        }
      }
    }
  }
  if self.builder.getInsertBlock().getTerminator() is None {
    let _ = self.builder.createBr(merge_bb)
    need_merge = true
  }
  self.builder.setInsertPoint(else_bb)
  let else_value : &@llvm.Value? = match else_block.stmts.length() {
    0 => None
    n => {
      else_block.stmts[:n - 1].each(stmt => self.stmt_codegen(stmt))
      let last = else_block.stmts[n - 1]
      match last {
        ExprStmt(expr) => self.expr_codegen(expr)
        _ => {
          self.stmt_codegen(last)
          None
        }
      }
    }
  }
  if self.builder.getInsertBlock().getTerminator() is None {
    let _ = self.builder.createBr(merge_bb)
    need_merge = true
  }
  if need_merge {
    self.builder.setInsertPoint(merge_bb)
    if !(then_block.ty is Unit) {
      let phi = self.builder.createPHI(
        self.type_codegen_concrete(then_block.ty),
      )
      if then_value is Some(then_value) {
        phi.addIncoming(then_value, then_bb)
      }
      if else_value is Some(else_value) {
        phi.addIncoming(else_value, else_bb)
      }
      Some(phi)
    } else {
      None
    }
  } else {
    merge_bb.removeFromParent()
    None
  }
}
