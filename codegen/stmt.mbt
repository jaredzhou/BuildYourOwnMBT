///|
pub fn Context::stmt_codegen(self : Self, stmt : @knf.KnfStmt) -> Unit raise {
  match stmt {
    Let(name, ty, expr) => self.let_stmt_codegen(name, ty, expr)
    LetMut(name, ty, expr) => self.let_mut_stmt_codegen(name, ty, expr)
    Assign(name, expr) => self.assign_stmt_codegen(name, expr)
    ArrayPut(name, idx, expr) => self.array_put_codegen(name, idx, expr)
    StructFieldSet(struct_name, field, value_name) =>
      self.struct_field_set_codegen(struct_name, field, value_name)
    While(cond, block) => self.while_stmt_codegen(cond, block)
    ExprStmt(expr) => {
      let _ = self.expr_codegen(expr)

    }
    Return(expr) => {
      let value = self.expr_codegen(expr)
      guard value is Some(value) else {
        raise CodegenError("expr_codegen returned None: \{expr}")
      }
      let _ = self.builder.createRet(value)

    }
    ReturnUnit => {
      let _ = self.builder.createRetVoid()

    }
    ClosureDef(closure) => {
      // Save current insert point before processing closure
      let saved_block = self.builder.getInsertBlock()
      self.closure_codegen(closure)
      // Restore insert point after processing closure
      self.builder.setInsertPoint(saved_block)
    }
  }
}

///|
fn Context::while_stmt_codegen(
  self : Self,
  cond : @knf.KnfBlock,
  body : @knf.KnfBlock,
) -> Unit raise {
  let current_func = self.builder.getInsertFunction()
  let cond_bb = current_func.addBasicBlock(name="while.cond")
  let body_bb = current_func.addBasicBlock(name="while.body")
  let merge_bb = current_func.addBasicBlock(name="while.merge")
  //entry_bb 直接跳转到cond_bb
  let _ = self.builder.createBr(cond_bb)
  //cond_bb
  self.builder.setInsertPoint(cond_bb)
  let n = cond.stmts.length()
  guard n > 0 else { raise CodegenError("cond block is empty") }
  cond.stmts[:n - 1].each(stmt => self.stmt_codegen(stmt))
  let last = cond.stmts[n - 1]
  guard last is ExprStmt(expr) else {
    raise CodegenError("cond block last stmt is not ExprStmt")
  }
  let cond_value = self.expr_codegen(expr)
  guard cond_value is Some(cond_value) else {
    raise CodegenError("cond_value is None")
  }
  let _ = self.builder.createCondBr(cond_value, body_bb, merge_bb)
  //body_bb
  self.builder.setInsertPoint(body_bb)
  body.stmts.each(stmt => self.stmt_codegen(stmt))
  let _ = self.builder.createBr(cond_bb)
  //merge_bb
  self.builder.setInsertPoint(merge_bb)
}

///|
pub fn Context::let_stmt_codegen(
  self : Self,
  name : @knf.Name,
  ty : @knf.Type,
  expr : @knf.KnfExpr,
) -> Unit raise {
  let value = self.expr_codegen(expr)
  guard value is Some(value) else {
    raise CodegenError("let stmt expr_codegen returned None: \{expr}")
  }
  self.name_values.set(name, value)
  self.name_types.set(name, ty)
}

///|
pub fn Context::let_mut_stmt_codegen(
  self : Self,
  name : @knf.Name,
  ty : @knf.Type,
  expr : @knf.KnfExpr,
) -> Unit raise {
  let value = self.expr_codegen(expr)
  guard value is Some(value) else {
    raise CodegenError("let mut expr_codegen returned None: \{expr}")
  }
  let ptr = self.builder.createAlloca(self.type_codegen_concrete(ty))
  let _ = self.builder.createStore(value, ptr)
  self.name_values.set(name, ptr)
  self.name_types.set(name, ty)
}

///|
pub fn Context::assign_stmt_codegen(
  self : Self,
  name : @knf.Name,
  expr : @knf.KnfExpr,
) -> Unit raise {
  let value = self.expr_codegen(expr)
  guard value is Some(value) else {
    raise CodegenError("assign stmt expr_codegen returned None: \{expr}")
  }
  let ptr = self.name_values.get(name)
  guard ptr is Some(ptr) else {
    raise CodegenError("name not found in name_values")
  }
  let _ = self.builder.createStore(value, ptr)

}

///|
pub fn Context::array_put_codegen(
  self : Self,
  name : @knf.Name,
  idx : @knf.Name,
  expr : @knf.KnfExpr,
) -> Unit raise {
  let value = self.expr_codegen(expr)
  guard value is Some(value) else {
    raise CodegenError("array put expr_codegen returned None: \{expr}")
  }
  let array_ty = self.name_types.get(name).unwrap()
  guard array_ty is Array(elem_ty) else {
    raise CodegenError("array_name not found: \{name}")
  }
  let array = self.name_values.get(name).unwrap()
  let index = self.name_values.get(idx).unwrap()
  let put_func = match elem_ty {
    Int => self.builtin_funcs.get("array_int_put").unwrap()
    Double => self.builtin_funcs.get("array_double_put").unwrap()
    Bool => self.builtin_funcs.get("array_bool_put").unwrap()
    _ => self.builtin_funcs.get("array_ptr_put").unwrap()
  }
  let _ = self.builder.createCall(put_func, [array, index, value])

}

///|
pub fn Context::struct_field_set_codegen(
  self : Self,
  name : @knf.Name,
  field : String,
  value_name : @knf.Name,
) -> Unit raise {
  let value = self.name_values.get(value_name)
  guard value is Some(value) else {
    raise CodegenError("value_name not found: \{value_name}")
  }
  let knf_struct_ty = self.name_types.get(name).unwrap()
  guard knf_struct_ty is Struct(struct_ty_name) else {
    raise CodegenError("name is not a struct")
  }
  let struct_ty = self.struct_types.get(struct_ty_name).unwrap()
  let struct_ptr = self.name_values.get(name).unwrap()
  let knf_struct_def = self.knf_struct_types.get(struct_ty_name).unwrap()
  let field_index = knf_struct_def.get_field_index(field).unwrap()
  let field_address = self.builder.createGEP(struct_ptr, struct_ty, [
    self.llvm_ctx.getConstInt32(0),
    self.llvm_ctx.getConstInt32(field_index),
  ])
  let _ = self.builder.createStore(value, field_address)

}
