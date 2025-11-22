///|
pub fn codegen(knf_prog : @knf.KnfProgram) -> @llvm.Module raise {
  let codegen_ctx = Context::new("demo")
  codegen_ctx.collect_struct_types(knf_prog.struct_defs)
  codegen_ctx.collect_func_values(knf_prog.functions)
  knf_prog.functions.each((_name, func) => {
    let _ = codegen_ctx.top_function_codegen(func)
    println("codegen function: \{func.name}")
  })
  codegen_ctx.llvm_mod
}
