///|
pub(all) struct KnfProgram {
  struct_defs : Map[String, KnfStructDef]
  top_lets : Map[String, KnfTopLet]
  functions : Map[String, KnfFunction]
}

///|
pub fn Context::program_to_knf(
  self : Context,
  prog : @typecheck.Program,
) -> KnfProgram raise KnfTransformError {
  let struct_defs = {}
  prog.struct_defs.each((name, struct_def) => {
    let knf_struct_def = self.struct_def_to_knf(struct_def)
    struct_defs.set(name, knf_struct_def)
  })
  let top_lets = {}
  prog.top_lets.each((name, top_let) => {
    let knf_top_let = self.top_let_to_knf(top_let)
    top_lets.set(name, knf_top_let)
  })
  let functions = {}
  prog.top_functions.each((name, function) => {
    let knf_function = self.top_function_to_knf(function)
    functions.set(name, knf_function)
  })
  KnfProgram::{ struct_defs, top_lets, functions }
}

///|
pub fn knf_transform(
  prog : @typecheck.Program,
) -> KnfProgram raise KnfTransformError {
  let context = Context::new()
  context.globals.set("print_int", Function([Int], Unit))
  context.program_to_knf(prog)
}

///|
pub impl Show for KnfProgram with output(self, logger) {
  for _, struct_def in self.struct_defs {
    logger.write_object(struct_def)
    logger.write_char('\n')
  }
  for _, top_let in self.top_lets {
    logger.write_object(top_let)
    logger.write_char('\n')
  }
  for _, func in self.functions {
    logger.write_object(func)
    logger.write_char('\n')
  }
}
