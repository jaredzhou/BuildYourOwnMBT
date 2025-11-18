///|
pub(all) struct StructConstructExpr {
  name : String
  fields : Array[(String, Expr)]
} derive(Show)

///|
pub fn Context::check_struct_construct_expr(
  self : Self,
  sc_expr : @parser.StructConstructExpr,
) -> (AtomExprKind, TypeKind) raise TypeCheckError {
  let struct_def = self.struct_defs.get(sc_expr.name)
  guard struct_def is Some(struct_def) else {
    raise TypeCheckError("struct '\{sc_expr.name}' not defined")
  }
  guard sc_expr.fields.length() == struct_def.fields.length() else {
    raise TypeCheckError(
      "struct '\{sc_expr.name}' has different number of fields",
    )
  }
  let fields = sc_expr.fields.map(args => {
    let (field, value) = args
    guard struct_def.get_field_type(field) is Some(field_define) else {
      raise TypeCheckError(
        "struct '\{sc_expr.name}' field '\{field}' not found",
      )
    }
    let value = self.check_expr(value)
    guard self.is_type_compatible(value.ty, field_define.kind) else {
      raise TypeCheckError(
        "struct '\{sc_expr.name}' field '\{field}' type mismatch",
      )
    }
    (field, value)
  })
  (
    AtomExprKind::StructConstruct(StructConstructExpr::{
      name: sc_expr.name,
      fields,
    }),
    TypeKind::Struct(sc_expr.name),
  )
}
