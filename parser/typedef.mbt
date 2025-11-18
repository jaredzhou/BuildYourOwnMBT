///|
pub(all) struct Type {
  kind : TypeKind
} derive(Show, Eq)

///|
pub fn Type::new(kind : TypeKind) -> Type {
  Type::{ kind, }
}

///|
pub(all) enum TypeKind {
  Unit
  Bool
  Int
  Double
  String
  Tuple(Array[TypeKind])
  Array(TypeKind)
  Function(Array[TypeKind], TypeKind)
  Defined(String)
} derive(Hash, Eq) // Show defined manually in `parser_aux.mbt`

///|
pub fn parse_type(
  tokens : ArrayView[Token],
) -> (Type, ArrayView[Token]) raise ParseError {
  match tokens {
    [{ kind: Upper("Unit") }, .. rest] => (Type::new(TypeKind::Unit), rest)
    [{ kind: Upper("Bool") }, .. rest] => (Type::new(TypeKind::Bool), rest)
    [{ kind: Upper("Int") }, .. rest] => (Type::new(TypeKind::Int), rest)
    [{ kind: Upper("Double") }, .. rest] => (Type::new(TypeKind::Double), rest)
    [{ kind: Upper("String") }, .. rest] => (Type::new(TypeKind::String), rest)
    [{ kind: Bracket('(') }, ..] as rest => {
      let (args, rest) = parse_list_type(Bracket('('), Bracket(')'), rest)
      match rest {
        [{ kind: Symbol("->") }, .. rest] => {
          let (ret, rest) = parse_type(rest)
          (Type::new(TypeKind::Function(args, ret.kind)), rest)
        }
        _ => (Type::new(TypeKind::Tuple(args)), rest)
      }
    }
    [{ kind: Upper("Array") }, { kind: Bracket('[') }, .. rest] => {
      let (ty, rest) = parse_type(rest)
      guard rest is [{ kind: Bracket(']') }, .. rest] else {
        raise ParseError("Unexpected token: \{rest[0]}")
      }
      (Type::new(TypeKind::Array(ty.kind)), rest)
    }
    [{ kind: Upper(name) }, .. rest] =>
      (Type::new(TypeKind::Defined(name)), rest)
    _ => raise ParseError("Unexpected token: \{tokens[0]}")
  }
}

///|
pub impl Show for TypeKind with output(self, logger) {
  let s = match self {
    Unit => "Unit"
    Bool => "Bool"
    Int => "Int"
    Double => "Double"
    String => "String"
    Tuple(tys) => {
      let inner = tys.map(ty => ty.to_string()).join(", ")
      "(\{inner})"
    }
    Array(ty) => "Array[\{ty}]"
    Function(params, ret) => {
      let param_str = params.map(ty => ty.to_string()).join(", ")
      "(\{param_str}) -> \{ret}"
    }
    Defined(name) => name
  }
  logger.write_string(s)
}

///|
pub fn parse_list_type(
  lbracket : @lexer.TokenKind,
  rbracket : @lexer.TokenKind,
  tokens : ArrayView[Token],
) -> (Array[TypeKind], ArrayView[Token]) raise ParseError {
  guard tokens is [{ kind: lb }, .. tokens] && lb == lbracket else {
    raise ParseError("Unexpected token: \{tokens[0]}")
  }
  let types : Array[TypeKind] = []
  loop tokens {
    // 遇到右括号，结束解析并返回结果
    [{ kind: rb }, .. rest] if rb == rbracket => (types, rest)

    // 解析模式, 如果有逗号， 跳过逗号
    // 处理逗号后的情况：支持尾随逗号，不允许连续逗号，开头逗号，多个尾随逗号
    // 开头是逗号， 连续逗号， 多个尾随逗号，都会执行到parse_pattern， 然后报错
    //一个尾随逗号或者没有尾随逗号都会正常解析
    tokens => {
      let (ty, rest) = parse_type(tokens)
      types.push(ty.kind)
      //一个type后面要么是",",要么是"}" 不能是其他的
      match rest {
        [{ kind: Symbol(",") }, .. rest] => continue rest
        [{ kind: rb }, ..] if rb == rbracket => continue rest
        _ => raise ParseError("Unexpected token: \{rest[0]}")
      }
    }
  }
}
