///|
pub fn Context::stmt_codegen(
  self : Self,
  stmt : @knf.KnfStmt,
  is_last? : Bool = false,
) -> Unit raise {
  match stmt {
    Let(name, ty, expr) => self.let_stmt_codegen(name, ty, expr)
    LetMut(name, ty, expr) => self.let_mut_stmt_codegen(name, ty, expr)
    Assign(name, expr) => self.assign_stmt_codegen(name, expr)
    ArrayPut(_) => raise CodegenError("ArrayPut not implemented yet")
    StructFieldSet(_) =>
      raise CodegenError("StructFieldSet not implemented yet")
    While(_) => raise CodegenError("While not implemented yet")
    ExprStmt(expr) => {
      let expr_value = self.expr_codegen(expr)
      guard expr_value is Some(expr_value) else {
        raise CodegenError("expr_codegen returned None")
      }
      if is_last {
        let _ = self.builder.createRet(expr_value)

      }
    }
    Return(expr) => {
      let expr_value = self.expr_codegen(expr)
      guard expr_value is Some(expr_value) else {
        raise CodegenError("expr_codegen returned None")
      }
      let _ = self.builder.createRet(expr_value)

    }
    ReturnUnit => {
      let _ = self.builder.createRetVoid()

    }
    ClosureDef(_) => raise CodegenError("ClosureDef not implemented yet")
  }
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
    raise CodegenError("expr_codegen returned None")
  }
  self.name_values.set(name, value)
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
    raise CodegenError("expr_codegen returned None")
  }
  let ptr = self.builder.createAlloca(self.type_codegen_concrete(ty))
  let _ = self.builder.createStore(value, ptr)
  self.name_values.set(name, ptr)
}

///|
pub fn Context::assign_stmt_codegen(
  self : Self,
  name : @knf.Name,
  expr : @knf.KnfExpr,
) -> Unit raise {
  let value = self.expr_codegen(expr)
  guard value is Some(value) else {
    raise CodegenError("expr_codegen returned None")
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
  ignore(self)
  ignore(name)
  ignore(idx)
  ignore(expr)
  raise CodegenError("ArrayPut codegen not implemented yet")
}

///|
pub fn Context::struct_field_set_codegen(
  self : Self,
  name : @knf.Name,
  field : String,
  value_name : @knf.Name,
) -> Unit raise {
  ignore(self)
  ignore(name)
  ignore(field)
  ignore(value_name)
  raise CodegenError("StructFieldSet codegen not implemented yet")
}
