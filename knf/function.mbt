///|
pub(all) struct KnfFunction {
  name : String
  ret_ty : Type
  params : Array[(Name, Type)]
  body : KnfBlock
}

///|
pub fn Context::top_function_to_knf(
  self : Context,
  top_func : @typecheck.TopFunction,
) -> KnfFunction raise KnfTransformError {
  self.enter_scope()
  let params = top_func.param_list.map(param => {
    let ty = self.typekind_to_knf(param.ty)
    let name = self.add_new_name(param.name, ty)
    (name, ty)
  })
  let ret_ty = self.typekind_to_knf(top_func.ret_ty)
  let func_ty = Type::Function(params.map(param => param.1), ret_ty)
  ignore(self.add_new_name(top_func.fname, func_ty))
  let body = self.block_expr_to_knf(top_func.body)
  self.exit_scope()
  let func = KnfFunction::{ name: top_func.fname, ret_ty, params, body }
  self.globals.set(top_func.fname, func_ty)
  func
}

///|
pub impl Show for KnfFunction with output(self, logger) {
  let { name, ret_ty, params, body } = self
  logger.write_string("fn \{name}")
  if name != "main" {
    logger.write_string("(")
    let param_str = params
      .map(param => {
        let (param_name, param_ty) = param
        "\{param_name}: \{param_ty}"
      })
      .join(", ")
    logger.write_string(param_str)
    logger.write_string(") -> \{ret_ty}")
  }
  logger.write_char(' ')
  logger.write_object(body)
}
