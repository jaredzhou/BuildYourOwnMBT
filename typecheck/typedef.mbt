///|
pub(all) struct Type {
  kind : TypeKind
  mutable : Bool
} derive(Show)

///|
pub(all) enum TypeKind {
  Unit
  Bool
  Int
  Double
  String
  Tuple(Array[TypeKind])
  Array(TypeKind)
  Function(Array[TypeKind], TypeKind)
  Struct(String)
  Any
  TypeVar(Int)
} derive(Hash)

///|
pub fn Context::check_parser_typekind(
  self : Context,
  ty : @parser.TypeKind,
) -> TypeKind raise TypeCheckError {
  match ty {
    Unit => TypeKind::Unit
    Bool => TypeKind::Bool
    Int => TypeKind::Int
    Double => TypeKind::Double
    String => TypeKind::String
    Tuple(tys) => TypeKind::Tuple(tys.map(ty => self.check_parser_typekind(ty)))
    Array(ty) => TypeKind::Array(self.check_parser_typekind(ty))
    Function(params, ret) =>
      TypeKind::Function(
        params.map(ty => self.check_parser_typekind(ty)),
        self.check_parser_typekind(ret),
      )
    Defined(name) =>
      if self.struct_defs.contains(name) {
        TypeKind::Struct(name)
      } else {
        raise TypeCheckError("Struct \{name} not defined")
      }
  }
}

///|
pub fn Context::check_parser_type(
  self : Context,
  ty : @parser.Type,
  mutable? : Bool = false,
) -> Type raise TypeCheckError {
  let ty = self.check_parser_typekind(ty.kind)
  Type::{ kind: ty, mutable }
}

///|
/// 设置两个类型兼容, 如果兼容则返回true, 并且进行信息传递
pub fn Context::is_type_compatible(
  self : Context,
  a : TypeKind,
  b : TypeKind,
) -> Bool raise TypeCheckError {
  match (a, b) {
    //两个类型变量兼容
    (TypeVar(id_a), TypeVar(id_b)) => {
      let ty_a = self.deref_type_var(id_a)
      let ty_b = self.deref_type_var(id_b)
      match (ty_a, ty_b) {
        (TypeVar(_), TypeVar(_)) => {
          self.type_vars.set(id_a, b)
          true
        }
        (TypeVar(id_ty_a), ty_b) => {
          self.set_var_type_to_typekind(id_ty_a, ty_b)
          true
        }
        (_, TypeVar(_)) => false
        (_, _) => self.is_type_compatible(ty_a, ty_b)
      }
    }
    //一个类型变量与具体类型兼容
    //如果这个类型变量没有被赋值，则将它赋值为具体类型， 这包括一个一个信息传递的过程
    //比如 TVar(1) = TVar(0), 现在已知TVar(0) = Int 那么TVar(1)也必须等于 Int
    //如果现在知道TVar(1) = Int, 先找到TVar(0), 通过设置TVar(0) = Int来完成信息传递
    (TypeVar(id_a), ty_b) => {
      let ty_a = self.deref_type_var(id_a)
      if ty_a is TypeVar(id_ty_a) {
        self.set_var_type_to_typekind(id_ty_a, ty_b)
        true
      } else {
        self.is_type_compatible(ty_a, ty_b)
      }
    }
    (ty_a, TypeVar(_) as b) => self.is_type_compatible(b, ty_a)
    (Unit, Unit) => true
    (Bool, Bool) => true
    (Int, Int) => true
    (Double, Double) => true
    (String, String) => true
    (Tuple(tys_a), Tuple(tys_b)) =>
      if tys_a.length() != tys_b.length() {
        false
      } else {
        tys_a.zip(tys_b)[:].all(t => {
          let (ty_a, ty_b) = t
          self.is_type_compatible(ty_a, ty_b)
        })
      }
    (Array(elem_type_a), Array(elem_type_b)) =>
      self.is_type_compatible(elem_type_a, elem_type_b)
    (Function(params_a, ret_type_a), Function(params_b, ret_type_b)) =>
      if params_a.length() != params_b.length() {
        false
      } else {
        params_a.zip(params_b)[:].all(t => {
          let (param_a, param_b) = t
          self.is_type_compatible(param_a, param_b)
        }) &&
        self.is_type_compatible(ret_type_a, ret_type_b)
      }
    (Struct(name_a), Struct(name_b)) => name_a == name_b
    (Any, Any) => true
    _ => false
  }
}

///|
///   let _ = ctx.is_type_compatible(TypeVar(0), TypeVar(1))
///  let _ = ctx.is_type_compatible(TypeVar(1), TypeVar(2))
//  let _ = ctx.is_type_compatible(TypeVar(2), TypeVar(3))
//  let _ = ctx.is_type_compatible(TypeVar(3), TypeVar(0))
//  let _ = ctx.is_type_compatible(TypeVar(2), Tuple([Double, Int]))

fn Context::deref_type_var(self : Context, id : Int) -> TypeKind {
  let visited : Array[Int] = []
  fn deref_ty(id : Int) -> TypeKind {
    if visited.contains(id) {
      return TypeVar(id)
    }
    visited.push(id)
    let ty = self.type_vars.get(id).unwrap_or(TypeVar(id))
    match ty {
      TypeVar(ty_id) if ty_id != id => deref_ty(ty_id)
      _ => ty
    }
  }

  deref_ty(id)
}

///|
/// type var与具体类型合一, 同时进行信息传递
/// 比如 TVar(0) = Int, 那么 TVar(1) = TVar(0) 也必须等于 Int
/// 另外Tvar(1)也必须继续信息传递， 如果存在的话
fn Context::set_var_type_to_typekind(
  self : Context,
  target_id : Int,
  target_ty : TypeKind,
) -> Unit {
  self.type_vars.set(target_id, target_ty)
  for id, ty in self.type_vars {
    if ty is TypeVar(ty_id) && ty_id == target_id {
      self.set_var_type_to_typekind(id, target_ty)
    }
  }
}

///|
pub impl Show for TypeKind with output(self, logger) {
  let s = match self {
    Unit => "Unit"
    Bool => "Bool"
    Int => "Int"
    Double => "Double"
    String => "String"
    Tuple(types) => {
      let inner = types.map(typekind => typekind.to_string()).join(", ")
      "(\{inner})"
    }
    Array(elem_type) => "Array[\{elem_type.to_string()}]"
    Function(param_types, return_type) => {
      let params = param_types.map(typekind => typekind.to_string()).join(", ")
      "(\{params}) -> \{return_type.to_string()}"
    }
    Struct(name) => "\{name}"
    Any => "Any"
    TypeVar(name) => "TypeVar(\{name})"
  }
  logger.write_string(s)
}
