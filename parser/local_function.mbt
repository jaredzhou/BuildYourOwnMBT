///|
pub(all) struct LocalFunction {
  fname : String
  param_list : Array[(String, Type?)]
  ret_ty : Type?
  body : BlockExpr
} derive(Show, Eq)

///|
pub fn parse_local_function(
  tokens : ArrayView[Token],
) -> (LocalFunction, ArrayView[Token]) raise ParseError {
  guard tokens is [{ kind: Keyword(Fn) }, { kind: Lower(fname) }, .. rest] else {
    raise ParseError("local_function: Unexpected token: \{tokens[0]}")
  }
  let (params, rest) = parse_param_list(rest)
  let param_list = params.map(fn(param) { (param.name, param.ty) })
  let (ret_ty, rest) = if rest is [{ kind: Symbol("->") }, .. rest] {
    let (ret_ty, rest) = parse_type(rest)
    (Some(ret_ty), rest)
  } else {
    (None, rest)
  }
  let (body, rest) = parse_block_expr(rest)
  (LocalFunction::{ fname, param_list, ret_ty, body }, rest)
}

///|
pub fn parse_param_list(
  tokens : ArrayView[Token],
) -> (Array[Param], ArrayView[Token]) raise ParseError {
  guard tokens is [{ kind: Bracket('(') }, .. tokens] else {
    raise ParseError("Unexpected token: \{tokens[0]}")
  }
  let param_list : Array[Param] = []
  loop tokens {
    [{ kind: Bracket(')') }, .. rest] => (param_list, rest)
    [{ kind: Symbol(",") }, .. rest] =>
      // 处理逗号后的情况：支持尾随逗号，不允许连续逗号，开头逗号，多个尾随逗号
      match rest {
        [{ kind: Symbol(",") }, .. rest] =>
          raise ParseError("Unexpected token: \{rest[0]}")
        _ => continue rest
      }
    // 解析普通表达式
    tokens => {
      let (param, rest_tokens) = parse_param(tokens)
      param_list.push(param)
      continue rest_tokens
    }
  }
}
