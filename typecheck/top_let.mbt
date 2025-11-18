///|
pub(all) struct TopLet {
  name : String
  ty : TypeKind
  expr : Expr
} derive(Show)

///|
pub fn Context::check_top_let(
  self : Context,
  top_let : @parser.TopLet,
) -> TopLet raise TypeCheckError {
  let expr = self.check_expr(top_let.expr)
  let ty = if top_let.ty is Some(ty) {
    let ty = self.check_parser_type(ty)
    guard self.is_type_compatible(expr.ty, ty.kind) else {
      raise TypeCheckError(
        "top let: type mismatch, '\{expr.ty}' and '\{ty.kind}'",
      )
    }
    ty.kind
  } else {
    expr.ty
  }
  self.type_env.set(top_let.name, Type::{ kind: ty, mutable: false })
  TopLet::{ name: top_let.name, ty, expr }
}
