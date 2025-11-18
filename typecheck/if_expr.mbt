///|
pub(all) struct IfExpr {
  cond : Expr
  then_block : BlockExpr
  else_block : Either[IfExpr, BlockExpr]?
  ty : TypeKind
} derive(Show)

///|
pub fn Context::check_if_expr(
  self : Context,
  if_expr : @parser.IfExpr,
) -> IfExpr raise TypeCheckError {
  let cond = self.check_expr(if_expr.cond)
  guard cond.ty is Bool else {
    raise TypeCheckError("condition must be a boolean")
  }
  let then_block = self.check_block_expr(if_expr.then_block)
  let else_block = if if_expr.else_block is Some(else_block) {
    match else_block {
      Left(if_expr) => Some(Either::Left(self.check_if_expr(if_expr)))
      Right(block_expr) =>
        Some(Either::Right(self.check_block_expr(block_expr)))
    }
  } else {
    None
  }
  let else_type = if else_block is Some(else_block) {
    match else_block {
      Left(if_expr) => if_expr.ty
      Right(block_expr) => block_expr.ty
    }
  } else {
    Unit
  }
  guard self.is_type_compatible(then_block.ty, else_type) else {
    raise TypeCheckError("then and else branches have incompatible types")
  }
  let unified_ty = self.deref_type_kind(then_block.ty)
  IfExpr::{ cond, then_block, else_block, ty: unified_ty }
}
