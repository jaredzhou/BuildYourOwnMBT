///|
pub(all) struct StructDef {
  name : String
  fields : Array[StructField]
} derive(Show, Eq)

///|
pub(all) struct StructField {
  name : String
  is_mut : Bool
  ty : Type
} derive(Show, Eq)

///|
pub fn parse_struct_field(
  tokens : ArrayView[Token],
) -> (StructField, ArrayView[Token]) raise ParseError {
  let (is_mut, tokens) = if tokens is [{ kind: Keyword(Mut) }, .. rest] {
    (true, rest)
  } else {
    (false, tokens)
  }
  guard tokens is [{ kind: Lower(name) }, { kind: Symbol(":") }, .. tokens] else {
    raise ParseError("Expected field name")
  }
  let (ty, tokens) = parse_type(tokens)
  (StructField::{ name, is_mut, ty }, tokens)
}

///|
pub fn parse_struct_def(
  tokens : ArrayView[Token],
) -> (StructDef, ArrayView[Token]) raise ParseError {
  guard tokens
    is [
      { kind: Keyword(Struct) },
      { kind: Upper(name) },
      { kind: Bracket('{') },
      .. tokens,
    ] else {
    raise ParseError("Expected struct name")
  }
  let fields : Array[StructField] = []
  loop tokens {
    [{ kind: Bracket('}') }, .. rest] => (StructDef::{ name, fields }, rest)
    tokens => {
      let (field, rest) = parse_struct_field(tokens)
      fields.push(field)
      guard rest is [{ kind: Symbol(";") }, .. rest] else {
        raise ParseError("Expected ';' after struct field")
      }
      continue rest
    }
  }
}
