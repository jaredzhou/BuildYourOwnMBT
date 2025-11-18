///|
pub(all) struct ApplyExpr {
  kind : ApplyExprKind
  ty : TypeKind
} derive(Show)

///|
pub(all) enum ApplyExprKind {
  AtomExpr(AtomExpr)
  ArrayAccess(ApplyExpr, Expr)
  FieldAccess(ApplyExpr, String)
  Call(ApplyExpr, Array[Expr])
} derive(Show)

///|
pub fn Context::check_apply_expr(
  self : Self,
  apply_expr : @parser.ApplyExpr,
) -> ApplyExpr raise TypeCheckError {
  match apply_expr.kind {
    AtomExpr(atom_expr) => {
      let atom_expr = self.check_atom_expr(atom_expr)
      ApplyExpr::{ kind: AtomExpr(atom_expr), ty: atom_expr.ty }
    }
    ArrayAccess(apply_expr, index_expr) => {
      let apply_expr = self.check_apply_expr(apply_expr)
      guard apply_expr.ty is TypeKind::Array(elem_type) else {
        raise TypeCheckError(
          "array access: expected array, got \{apply_expr.ty}",
        )
      }
      let index_expr = self.check_expr(index_expr)
      guard index_expr.ty is TypeKind::Int else {
        raise TypeCheckError(
          "array access: expected integer index, got \{index_expr.ty}",
        )
      }
      ApplyExpr::{ kind: ArrayAccess(apply_expr, index_expr), ty: elem_type }
    }
    FieldAccess(apply_expr, field_name) => {
      let apply_expr = self.check_apply_expr(apply_expr)
      match apply_expr.ty {
        TypeKind::Struct(struct_name) => {
          let field_type = self.struct_defs
            .get(struct_name)
            .unwrap_or_else(() => raise TypeCheckError(
              "struct \{struct_name} not found",
            ))
            .get_field_type(field_name)
          guard field_type is Some(field_type) else {
            raise TypeCheckError(
              "field access: field \{field_name} not found in struct \{struct_name}",
            )
          }
          ApplyExpr::{
            kind: FieldAccess(apply_expr, field_name),
            ty: field_type.kind,
          }
        }
        TypeKind::Array(elem_type) =>
          match field_name {
            "push" =>
              ApplyExpr::{
                kind: FieldAccess(apply_expr, field_name),
                ty: Function([elem_type], Unit),
              }
            "length" =>
              ApplyExpr::{
                kind: FieldAccess(apply_expr, field_name),
                ty: Function([], Int),
              }
            _ =>
              raise TypeCheckError(
                "field access: field \{field_name} not found in array",
              )
          }
        _ =>
          raise TypeCheckError(
            "field access: expected struct or array, got \{apply_expr.ty}",
          )
      }
    }
    Call(callee_expr, arg_exprs) => {
      let callee_expr = self.check_apply_expr(callee_expr)
      guard callee_expr.ty is TypeKind::Function(param_types, ret_type) else {
        raise TypeCheckError(
          "call: '\{apply_expr}' expected function, got \{callee_expr.ty}",
        )
      }
      let arg_exprs = arg_exprs.map(expr => self.check_expr(expr))
      guard arg_exprs.length() == param_types.length() else {
        raise TypeCheckError(
          "call: expected \{param_types.length()} arguments, got \{arg_exprs.length()}",
        )
      }
      //param类型与arg类型要一一对应
      guard arg_exprs.zip(param_types)[:].all(t => {
        let (arg_expr, param_type) = t
        let is_compatible = self.is_type_compatible(arg_expr.ty, param_type)
        if !is_compatible {
          println(
            "call: argument types do not match function parameters, '\{apply_expr}'",
          )
          println("arg_expr.ty: \{arg_expr.ty}")
          println("param_type: \{param_type}")
        }
        is_compatible
      }) else {
        raise TypeCheckError(
          "call: argument types do not match function parameters, '\{apply_expr}'",
        )
      }
      let ret_type = match ret_type {
        TypeKind::TypeVar(id) => self.type_vars.get(id).unwrap()
        _ => ret_type
      }
      ApplyExpr::{ kind: Call(callee_expr, arg_exprs), ty: ret_type }
    }
  }
}
