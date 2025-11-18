///|
pub(all) struct AtomExpr {
  kind : AtomExprKind
  ty : TypeKind
} derive(Show)

///|
pub(all) enum AtomExprKind {
  Int(Int) // 1, 42, etc
  Double(Double) // 1.0, 3.14, etc
  Bool(Bool) // true | false
  String(String) // "hello", etc
  Ident(String) // var
  Unit // ()
  Paren(Expr) // (expr)
  Tuple(Array[Expr]) // (expr, expr, ...)
  Array(Array[Expr]) // [expr, expr, ...]
  ArrayMake(Expr, Expr) // Array::make(size, init)
  StructConstruct(StructConstructExpr) // StructName::{ field: expr, ... }
} derive(Show)

///|
/// 生成一个新的类型变量 ID
fn Context::fresh_type_var_id(self : Context) -> Int {
  let mut max_id = -1
  for id, _ in self.type_vars {
    if id > max_id {
      max_id = id
    }
  }
  max_id + 1
}

///|
/// 检查数组表达式
fn Context::check_array_expr(
  self : Context,
  exprs : Array[@parser.Expr],
) -> AtomExpr raise TypeCheckError {
  guard exprs.length() > 0 else {
    // 空数组：创建新的类型变量作为元素类型
    let type_var_id = self.fresh_type_var_id()
    let elem_type = TypeVar(type_var_id)
    self.type_vars.set(type_var_id, elem_type)
    let array_kind = TypeKind::Array(elem_type)
    return AtomExpr::{ kind: Array([]), ty: array_kind }
  }
  let checked_exprs = exprs.map(expr => self.check_expr(expr))
  // 非空数组：检查所有元素类型是否兼容
  let first_elem_type = checked_exprs[0].ty
  for i = 1; i < checked_exprs.length(); i = i + 1 {
    let elem_type = checked_exprs[i].ty
    guard self.is_type_compatible(first_elem_type, elem_type) else {
      raise TypeCheckError(
        "array element type mismatch: expected compatible with \{first_elem_type}, got \{elem_type}",
      )
    }
  }
  AtomExpr::{ kind: Array(checked_exprs), ty: TypeKind::Array(first_elem_type) }
}

///|
pub fn Context::check_atom_expr(
  self : Self,
  atom_expr : @parser.AtomExpr,
) -> AtomExpr raise TypeCheckError {
  match atom_expr.kind {
    Int(value) => AtomExpr::{ kind: Int(value), ty: TypeKind::Int }
    Double(value) => AtomExpr::{ kind: Double(value), ty: TypeKind::Double }
    Bool(value) => AtomExpr::{ kind: Bool(value), ty: TypeKind::Bool }
    String(value) => AtomExpr::{ kind: String(value), ty: TypeKind::String }
    Ident(name) =>
      match self.type_env.get(name) {
        Some(ty) => AtomExpr::{ kind: Ident(name), ty: ty.kind }
        None =>
          raise TypeCheckError(
            "variable '\{name}': type not defined in context",
          )
      }
    Unit => AtomExpr::{ kind: Unit, ty: TypeKind::Unit }
    Paren(expr) => {
      let expr = self.check_expr(expr)
      AtomExpr::{ kind: Paren(expr), ty: expr.ty }
    }
    Tuple(exprs) => {
      let exprs = exprs.map(expr => self.check_expr(expr))
      AtomExpr::{
        kind: Tuple(exprs),
        ty: TypeKind::Tuple(exprs.map(expr => expr.ty)),
      }
    }
    Array(exprs) => self.check_array_expr(exprs)
    ArrayMake(size_expr, init_expr) => {
      let size_expr = self.check_expr(size_expr)
      guard size_expr.ty is TypeKind::Int else {
        raise TypeCheckError("size expression must be an integer")
      }
      let init_expr = self.check_expr(init_expr)
      AtomExpr::{
        kind: ArrayMake(size_expr, init_expr),
        ty: TypeKind::Array(init_expr.ty),
      }
    }
    StructConstruct(sc_expr) => {
      let (kind, ty) = self.check_struct_construct_expr(sc_expr)
      AtomExpr::{ kind, ty }
    }
  }
}
