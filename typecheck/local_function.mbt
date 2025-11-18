///|
pub(all) struct LocalFunction {
  fname : String
  param_list : Array[(String, Type)]
  ret_ty : Type
  body : BlockExpr
} derive(Show)

///|
pub fn Context::check_local_function(
  self : Context,
  func : @parser.LocalFunction,
) -> LocalFunction raise TypeCheckError {
  let param_list = func.param_list.map(fn(param) {
    let (name, ty) = param
    let ty = if ty is Some(ty) {
      self.check_parser_type(ty)
    } else {
      let type_var_id = self.fresh_type_var_id()
      let type_var = TypeKind::TypeVar(type_var_id)
      self.type_vars.set(type_var_id, type_var)
      Type::{ kind: type_var, mutable: false }
    }
    (name, ty)
  })
  let ret_ty = if func.ret_ty is Some(ret_ty) {
    self.check_parser_type(ret_ty)
  } else {
    let type_var_id = self.fresh_type_var_id()
    let type_var = TypeKind::TypeVar(type_var_id)
    self.type_vars.set(type_var_id, type_var)
    Type::{ kind: type_var, mutable: false }
  }
  let func_ty = TypeKind::Function(
    param_list.map(fn(param) { param.1.kind }),
    ret_ty.kind,
  )
  self.type_env.set(func.fname, Type::{ kind: func_ty, mutable: false })
  self.enter_scope()
  self.set_current_func_ret_ty(ret_ty.kind)
  param_list.each(fn(param) {
    let (name, ty) = param
    self.type_env.set(name, ty)
  })
  let body = self.check_block_expr(func.body)
  guard self.is_type_compatible(body.ty, ret_ty.kind) else {
    raise TypeCheckError(
      "local function: type mismatch, '\{body.ty}' and '\{ret_ty.kind}'",
    )
  }
  self.exit_scope()
  LocalFunction::{ fname: func.fname, param_list, ret_ty, body }
}
