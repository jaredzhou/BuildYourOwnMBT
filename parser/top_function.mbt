///|
pub(all) struct Param {
  name : String
  ty : Type?
} derive(Show, Eq)

///|
pub(all) struct TopFunction {
  fname : String
  param_list : Array[Param]
  ret_ty : Type?
  body : BlockExpr
} derive(Show, Eq)

///|
pub fn parse_param(
  tokens : ArrayView[Token],
) -> (Param, ArrayView[Token]) raise ParseError {
  guard tokens is [{ kind: Lower(name) }, .. tokens] else {
    raise ParseError("top function param Unexpected token: \{tokens[0]}")
  }
  let (ty, tokens) = if tokens is [{ kind: Symbol(":") }, .. tokens] {
    let (ty, tokens) = parse_type(tokens)
    (Some(ty), tokens)
  } else {
    (None, tokens)
  }
  (Param::{ name, ty }, tokens)
}

///|
pub fn parse_top_function(
  tokens : ArrayView[Token],
) -> (TopFunction, ArrayView[Token]) raise ParseError {
  guard tokens is [{ kind: Keyword(Fn) }, { kind: Lower(fname) }, .. rest] else {
    raise ParseError("top function Unexpected token: \{tokens[0]}")
  }
  match fname {
    "main" => {
      let (body, rest) = parse_block_expr(rest)
      (
        TopFunction::{
          fname,
          param_list: [],
          ret_ty: Some(Type::new(TypeKind::Unit)),
          body,
        },
        rest,
      )
    }
    _ => {
      let (param_list, rest) = parse_param_list(rest)
      guard rest is [{ kind: Symbol("->") }, .. rest] else {
        raise ParseError("top function Unexpected token: \{rest[0]}")
      }
      let (ret_ty, rest) = parse_type(rest)
      let (body, rest) = parse_block_expr(rest)
      (TopFunction::{ fname, param_list, ret_ty: Some(ret_ty), body }, rest)
    }
  }
}
