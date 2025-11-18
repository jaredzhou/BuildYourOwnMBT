///|
pub(all) struct LetStmt {
  pattern : Pattern
  ty : TypeKind
  expr : Expr
} derive(Show)

///|
pub(all) struct Pattern {
  kind : PatternKind
} derive(Show, Eq)

///|
pub(all) enum PatternKind {
  Wildcard
  Ident(String)
  Tuple(Array[Pattern])
} derive(Show, Eq)

///|
pub fn Context::check_let_stmt(
  self : Context,
  let_stmt : @parser.LetStmt,
) -> LetStmt raise TypeCheckError {
  let expr = self.check_expr(let_stmt.expr)
  let pattern = self.check_pattern(let_stmt.pattern)
  let ty_kind = if let_stmt.ty is Some(ty) {
    let ty = self.check_parser_type(ty)
    guard self.is_type_compatible(expr.ty, ty.kind) else {
      raise TypeCheckError("let: type mismatch, '\{expr.ty}' and '\{ty}'")
    }
    ty.kind
  } else {
    expr.ty
  }
  self.set_pattern_type(pattern, ty_kind)
  LetStmt::{ pattern, ty: ty_kind, expr }
}

///|
fn Context::check_pattern(
  self : Context,
  pattern : @parser.Pattern,
) -> Pattern raise TypeCheckError {
  match pattern.kind {
    @parser.PatternKind::Wildcard => Pattern::{ kind: PatternKind::Wildcard }
    @parser.PatternKind::Ident(name) =>
      Pattern::{ kind: PatternKind::Ident(name) }
    @parser.PatternKind::Tuple(patterns) => {
      let checked_patterns = patterns.map(pattern => self.check_pattern(pattern))
      Pattern::{ kind: PatternKind::Tuple(checked_patterns) }
    }
  }
}

///|
fn Context::set_pattern_type(
  self : Context,
  pattern : Pattern,
  ty : TypeKind,
) -> Unit raise TypeCheckError {
  match pattern.kind {
    PatternKind::Ident(name) =>
      self.type_env.set(name, Type::{ kind: ty, mutable: false })
    PatternKind::Tuple(patterns) => {
      guard ty is Tuple(tys) && tys.length() == patterns.length() else {
        raise TypeCheckError("let: type mismatch, '\{ty}' and '\{patterns}'")
      }
      patterns
      .zip(tys)
      .each(pair => {
        let (pattern, ty) = pair
        self.set_pattern_type(pattern, ty)
      })
    }
    PatternKind::Wildcard => ()
  }
}
