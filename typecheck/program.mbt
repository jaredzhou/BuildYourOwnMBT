///|
using @either {type Either}

///|
pub(all) suberror TypeCheckError String derive(Show)

///|
pub(all) struct Env {
  local_ : Map[String, Type]
  parent : Env?
}

///|
pub fn Env::new(parent? : Env? = None) -> Env {
  Env::{ local_: Map::new(), parent }
}

///|
pub fn Env::get(self : Env, name : String) -> Type? {
  match self.local_.get(name) {
    Some(t) => Some(t)
    None =>
      match self.parent {
        Some(p) => p.get(name)
        None => None
      }
  }
}

///|
pub fn Env::set(self : Env, name : String, t : Type) -> Unit {
  self.local_.set(name, t)
}

///|
pub(all) struct Context {
  mut type_env : Env
  type_vars : Map[Int, TypeKind]
  struct_defs : Map[String, StructDef]
  func_types : Map[String, TypeKind]
  mut current_func_ret_ty : TypeKind?
}

///|
pub fn Context::new() -> Context {
  Context::{
    type_env: Env::new(),
    type_vars: Map::new(),
    struct_defs: Map::new(),
    func_types: Map::new(),
    current_func_ret_ty: None,
  }
}

///|
pub fn Context::lookup_type(self : Context, name : String) -> Type? {
  let ty = self.type_env.get(name)
  guard ty is Some(ty) else { return None }
  let ty_kind = self.deref_type_kind(ty.kind)
  Some(Type::{ kind: ty_kind, mutable: ty.mutable })
}

///|
pub fn Context::enter_scope(self : Self) -> Unit {
  let sub_env = Env::new(parent=Some(self.type_env))
  self.type_env = sub_env
}

///|
pub fn Context::exit_scope(self : Context) -> Unit {
  self.type_env = match self.type_env.parent {
    Some(p) => p
    None => self.type_env
  }
}

///|
pub fn Context::set_current_func_ret_ty(self : Context, ty : TypeKind) -> Unit {
  self.current_func_ret_ty = Some(ty)
}

///|
pub(all) struct Program {
  top_lets : Map[String, TopLet]
  top_functions : Map[String, TopFunction]
  struct_defs : Map[String, StructDef]
} derive(Show)

///|
pub fn Context::check_program(
  self : Context,
  program : @parser.Program,
) -> Program raise TypeCheckError {
  self.collect_struct_names(program)
  self.collect_function_types(program)
  let struct_defs = {}
  program.struct_defs.each((name, struct_def) => struct_defs.set(
    name,
    self.check_struct_def(struct_def),
  ))
  let top_lets = {}
  program.top_lets.each((name, top_let) => top_lets.set(
    name,
    self.check_top_let(top_let),
  ))
  let top_functions = {}
  program.top_functions.each((name, top_function) => top_functions.set(
    name,
    self.check_top_function(top_function),
  ))
  Program::{ top_lets, top_functions, struct_defs }
}

///|
pub fn Context::collect_struct_names(
  self : Context,
  program : @parser.Program,
) -> Unit raise TypeCheckError {
  program.struct_defs.each((name, _) => self.struct_defs.set(name, StructDef::{
    name,
    fields: [],
  }))
}

///|
pub fn Context::collect_function_types(
  self : Context,
  program : @parser.Program,
) -> Unit raise TypeCheckError {
  program.top_functions.each((name, top_function) => {
    let param_list = top_function.param_list.map(param => {
      guard param.ty is Some(ty) else {
        raise TypeCheckError(
          "function '\{name}' parameter '\{param.name}' type is not defined",
        )
      }
      let ty = self.check_parser_type(ty)
      ty.kind
    })
    guard top_function.ret_ty is Some(ret_ty) else {
      raise TypeCheckError("function '\{name}' return type is not defined")
    }
    let ret_ty = self.check_parser_type(ret_ty)
    self.func_types.set(name, TypeKind::Function(param_list, ret_ty.kind))
    self.type_env.set(name, Type::{
      kind: TypeKind::Function(param_list, ret_ty.kind),
      mutable: false,
    })
  })
  program.top_lets.each((name, top_let) => {
    let ty = if top_let.ty is Some(ty) {
      self.check_parser_type(ty)
    } else {
      let type_var_id = self.fresh_type_var_id()
      let type_var = TypeKind::TypeVar(type_var_id)
      self.type_vars.set(type_var_id, type_var)
      Type::{ kind: type_var, mutable: false }
    }
    self.type_env.set(name, ty)
  })
}
