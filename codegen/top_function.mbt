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
    println("set param \{param.0} with value: \{arg}")
    self.name_values.set(param.0, arg)
  })
  if func.body.stmts.length() == 0 {
    let _ = self.builder.createRetVoid()

  } else {
    func.body.stmts.eachi((i, stmt) => self.stmt_codegen(
      stmt,
      is_last=i == func.body.stmts.length() - 1,
    ))
  }
  llvm_func
}
