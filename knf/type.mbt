///|
pub(all) enum Type {
  Unit
  Int
  Bool
  Double
  String
  Array(Type)
  Struct(String)
  Tuple(Array[Type])
  Function(Array[Type], Type)
}

///|
pub impl Show for Type with output(self, logger) {
  let s = match self {
    Unit => "Unit"
    Int => "Int"
    Bool => "Bool"
    Double => "Double"
    String => "String"
    Array(elem_type) => "Array[\{elem_type}]"
    Struct(name) => "\{name}"
    Tuple(elem_types) => {
      let elem_strs = elem_types.map(et => "\{et}").join(", ")
      "(\{elem_strs})"
    }
    Function(param_types, ret_type) => {
      let param_strs = param_types.map(pt => "\{pt}").join(", ")
      "(\{param_strs}) -> \{ret_type}"
    }
  }
  logger.write_string(s)
}

///|
pub fn Context::typekind_to_knf(
  self : Context,
  tk : @typecheck.TypeKind,
) -> Type raise KnfTransformError {
  match tk {
    Unit => Type::Unit
    Bool => Type::Bool
    Int => Type::Int
    Double => Type::Double
    String => Type::String
    Tuple(types) => Type::Tuple(types.map(ty => self.typekind_to_knf(ty)))
    Array(ty) => Type::Array(self.typekind_to_knf(ty))
    Function(params, ret) =>
      Type::Function(
        params.map(ty => self.typekind_to_knf(ty)),
        self.typekind_to_knf(ret),
      )
    Struct(name) => Type::Struct(name)
    _ => raise KnfTransformError("Unsupported type kind: \{tk}")
  }
}

///|
pub fn Context::type_to_knf(
  self : Context,
  t : @typecheck.Type,
) -> Type raise KnfTransformError {
  self.typekind_to_knf(t.kind)
}
