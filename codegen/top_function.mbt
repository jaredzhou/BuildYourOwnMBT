///|
///
/// 注意区分main函数与其他函数的codegen。
pub fn Context::top_function_codegen(
  self : Context,
  func : @knf.KnfFunction,
) -> @llvm.Function raise {
  let llvm_func = self.functions.get(func.name)
  guard llvm_func is Some(llvm_func) else {
    raise CodegenError("function '\{func.name}' not found")
  }
  let entry_block = llvm_func.addBasicBlock(name="entry")
  self.builder.setInsertPoint(entry_block)
  //预留了一个arg， 所以从第二个arg开始
  func.params.eachi((i, param) => {
    let arg = llvm_func.getArg(i + 1).unwrap()
    println("set param \{param.0} with value: \{arg} type: \{param.1}")
    self.name_values.set(param.0, arg)
    self.name_types.set(param.0, param.1)
  })
  if func.body.stmts.length() == 0 {
    let _ = self.builder.createRetVoid()
    return llvm_func
  }
  func.body.stmts[:func.body.stmts.length() - 1].each(stmt => self.stmt_codegen(
    stmt,
  ))
  let last_stmt = func.body.stmts[func.body.stmts.length() - 1]
  match last_stmt {
    ExprStmt(expr) => {
      let value = self.expr_codegen(expr)
      if value is Some(value) {
        println(
          "top function codegen creating ret with value: \{value}, type: \{value.getType()}",
        )
        println(
          "current insert function: \{self.builder.getInsertFunction().getName()}",
        )
        let _ = self.builder.createRet(value)

      }
    }
    Return(_) | ReturnUnit => self.stmt_codegen(last_stmt)
    _ => {
      self.stmt_codegen(last_stmt)
      let _ = self.builder.createRetVoid()

    }
  }
  llvm_func
}
