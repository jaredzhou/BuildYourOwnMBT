///|
pub(all) struct LetMutStmt {
  name : String
  ty : Type
  expr : Expr
} derive(Show)

///|
pub fn Context::check_let_mut_stmt(
  self : Context,
  stmt : @parser.LetMutStmt,
) -> LetMutStmt raise TypeCheckError {
  let expr = self.check_expr(stmt.expr)
  let ty_kind = if stmt.ty is Some(ty) {
    let ty = self.check_parser_type(ty)
    guard self.is_type_compatible(expr.ty, ty.kind) else {
      raise TypeCheckError("let mut: type mismatch, '\{expr.ty}' and '\{ty}'")
    }
    ty.kind
  } else {
    expr.ty
  }
  let ty = Type::{ kind: ty_kind, mutable: true }
  self.type_env.set(stmt.name, ty)
  LetMutStmt::{ name: stmt.name, ty, expr }
}
