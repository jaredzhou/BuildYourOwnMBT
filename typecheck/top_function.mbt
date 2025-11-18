///|
pub(all) struct Param {
  name : String
  ty : TypeKind
} derive(Show)

///|
pub(all) struct TopFunction {
  fname : String
  param_list : Array[Param]
  ret_ty : TypeKind
  body : BlockExpr
} derive(Show)

///|
pub fn Context::check_top_function(
  self : Context,
  func : @parser.TopFunction,
) -> TopFunction raise TypeCheckError {
  let func_type = self.func_types.get(func.fname)
  guard func_type is Some(Function(param_list, ret_ty)) else {
    raise TypeCheckError("function '\{func.fname}' not defined")
  }
  self.enter_scope()
  self.set_current_func_ret_ty(ret_ty)
  let param_list = func.param_list
    .zip(param_list)
    .map(param => {
      let (param, ty) = param
      self.type_env.set(param.name, Type::{ kind: ty, mutable: false })
      Param::{ name: param.name, ty }
    })
  let body = self.check_block_expr(func.body)
  guard self.is_type_compatible(body.ty, ret_ty) else {
    raise TypeCheckError(
      "function '\{func.fname}': type mismatch, '\{body.ty}' and '\{ret_ty}'",
    )
  }
  self.exit_scope()
  TopFunction::{ fname: func.fname, param_list, ret_ty, body }
}
