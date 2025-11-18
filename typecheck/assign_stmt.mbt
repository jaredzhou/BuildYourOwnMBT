///|
pub(all) struct LeftValue {
  kind : LeftValueKind
  ty : Type
} derive(Show)

///|
pub(all) enum LeftValueKind {
  Ident(String)
  ArrayAccess(LeftValue, Expr)
  FieldAccess(LeftValue, String)
} derive(Show)

///|
pub(all) struct AssignStmt {
  left_value : LeftValue
  op : AssignOp
  expr : Expr
} derive(Show)

///|
pub(all) enum AssignOp {
  Assign // =
  PlusAssign // +=
  MinusAssign // -=
  MultAssign // *=
  DivAssign // /=
  ModAssign // %=
} derive(Show, Eq)

///|
pub fn AssignOp::from_parser_assign_op(op : @parser.AssignOp) -> AssignOp {
  match op {
    Assign => Assign
    PlusAssign => PlusAssign
    MinusAssign => MinusAssign
    MultAssign => MultAssign
    DivAssign => DivAssign
    ModAssign => ModAssign
  }
}

///|
pub fn Context::check_assign_stmt(
  self : Context,
  assign_stmt : @parser.AssignStmt,
) -> AssignStmt raise TypeCheckError {
  let left_value = self.check_left_value(assign_stmt.left_value)
  guard left_value.ty.mutable is true else {
    raise TypeCheckError("left value is not mutable")
  }
  let expr = self.check_expr(assign_stmt.expr)
  guard self.is_type_compatible(left_value.ty.kind, expr.ty) else {
    raise TypeCheckError(
      "assign: type mismatch, '\{left_value.ty}' and '\{expr.ty}'",
    )
  }
  match assign_stmt.op {
    PlusAssign | MinusAssign | MultAssign | DivAssign | ModAssign => {
      guard self.deref_type_kind(left_value.ty.kind) is (Int | Double) else {
        raise TypeCheckError(
          "left value is not an int or double, \{assign_stmt.to_string()}",
        )
      }
      AssignStmt::{
        left_value,
        op: AssignOp::from_parser_assign_op(assign_stmt.op),
        expr,
      }
    }
    _ =>
      AssignStmt::{
        left_value,
        op: AssignOp::from_parser_assign_op(assign_stmt.op),
        expr,
      }
  }
}

///|
fn Context::check_left_value(
  self : Context,
  left_value : @parser.LeftValue,
) -> LeftValue raise TypeCheckError {
  match left_value.kind {
    @parser.LeftValueKind::Ident(name) => {
      let ty = self.type_env
        .get(name)
        .or_error(TypeCheckError("left value not found: \{name}"))
      LeftValue::{ kind: LeftValueKind::Ident(name), ty }
    }
    //数组元素总是mutable
    @parser.LeftValueKind::ArrayAccess(left_value, index) => {
      let left_value = self.check_left_value(left_value)
      guard left_value.ty.kind is Array(elem_type) else {
        raise TypeCheckError("left value is not an array")
      }
      let index = self.check_expr(index)
      guard self.is_type_compatible(index.ty, Int) else {
        raise TypeCheckError("index type mismatch")
      }
      LeftValue::{
        kind: LeftValueKind::ArrayAccess(left_value, index),
        ty: Type::{ kind: elem_type, mutable: true },
      }
    }
    @parser.LeftValueKind::FieldAccess(left_value, field) => {
      let left_value = self.check_left_value(left_value)
      guard left_value.ty.kind is Struct(struct_name) else {
        raise TypeCheckError("left value is not a struct")
      }
      let struct_def = self.struct_defs
        .get(struct_name)
        .or_error(TypeCheckError("struct \{struct_name} not defined"))
      LeftValue::{
        kind: LeftValueKind::FieldAccess(left_value, field),
        ty: struct_def
        .get_field_type(field)
        .or_error(
          TypeCheckError("field \{field} not found in struct \{struct_name}"),
        ),
      }
    }
  }
}
