///|
/// 表达式解析器 - 处理一元和二元表达式
/// 
/// 核心算法：
/// 1. 一元表达式：递归解析操作数，应用一元运算符
/// 2. 二元表达式：使用双栈算法处理运算符优先级，直接构建AST
/// 
/// 算法优势：
/// - 直接构建AST，无需中间转换
/// - 自然处理运算符优先级
/// - 支持复杂的嵌套表达式
/// 
/// 示例：
/// - 一元：!true, -42
/// - 二元：1 + 2 * 3, a && b || c
pub(all) struct Expr {
  kind : ExprKind
} derive(Show, Eq)

///|
pub fn Expr::new(kind : ExprKind) -> Expr {
  { kind, }
}

///|
pub(all) enum ExprKind {
  ApplyExpr(ApplyExpr)
  BlockExpr(BlockExpr)
  NotExpr(Expr)
  NegExpr(Expr)
  BinaryExpr(BinaryOp, Expr, Expr)
  IfExpr(IfExpr)
} derive(Show, Eq)

///|
pub(all) enum BinaryOp {
  Add // +
  Sub // -
  Mul // *
  Div // /
  Mod // %
  ShiftLeft // <<
  ShiftRight // >>
  Eq // ==
  NE // !=
  LT // <
  GT // >
  LE // <=
  GE // >=
  And // &&
  Or // ||
  BitAnd // &
  BitOr // |
} derive(Show, Eq)

///|
fn BinaryOp::from_tok_binary_op(tok_bin_op : @lexer.BinaryOp) -> BinaryOp {
  match tok_bin_op {
    Add => Add
    Sub => Sub
    Mul => Mul
    Div => Div
    Mod => Mod
    ShiftLeft => ShiftLeft
    ShiftRight => ShiftRight
    Eq => Eq
    NE => NE
    LT => LT
    GT => GT
    LE => LE
    GE => GE
    And => And
    Or => Or
    BitAnd => BitAnd
    BitOr => BitOr
  }
}

///|
/// 解析表达式的顶层入口函数
/// 
/// 处理两种主要情况：
/// 1. 一元表达式：!expr, -expr
/// 2. 二元表达式：通过双栈算法处理运算符优先级
/// 
/// 策略：先解析第一个操作数，如果后面有二元运算符则进入二元表达式解析
pub fn parse_expr(
  tokens : ArrayView[Token],
) -> (Expr, ArrayView[Token]) raise ParseError {
  match tokens {
    [{ kind: Keyword(If) }, ..] as rest => {
      let (if_expr, rest) = parse_if_expr(rest)
      (Expr::new(ExprKind::IfExpr(if_expr)), rest)
    }
    [{ kind: Bracket('{') }, ..] as rest => {
      let (block_expr, rest) = parse_block_expr(rest)
      (Expr::new(ExprKind::BlockExpr(block_expr)), rest)
    }
    [token, .. rest_tokens] if is_unary_op(token) => {
      // 处理一元表达式：递归解析操作数，然后应用一元运算符
      let (expr, rest_tokens) = parse_expr(rest_tokens)
      let unary_expr = unary_expr(token, expr)
      (unary_expr, rest_tokens)
    }
    tokens => {
      // 先解析第一个操作数
      let (apply_expr, rest) = parse_apply_expr(tokens)
      let expr = Expr::new(ExprKind::ApplyExpr(apply_expr))
      match rest {
        [{ kind: BinaryOp(_) }, ..] =>
          // 后面有二元运算符，进入二元表达式解析
          parse_binary_expr(expr, rest)
        _ =>
          // 没有二元运算符，返回简单的ApplyExpr
          (expr, rest)
      }
    }
  }
}

///|
/// 二元表达式解析器 - 使用双栈算法处理运算符优先级
/// 
/// 算法核心思想：
/// 1. 表达式栈(expr_stack)：存储已解析的表达式节点
/// 2. 运算符栈(op_stack)：存储待处理的运算符
/// 3. 优先级比较：高优先级运算符在树的深层，低优先级在浅层
/// 
/// 处理流程：
/// - 遇到运算符：与栈顶运算符比较优先级，决定是否立即组合
/// - 遇到操作数：解析后压入表达式栈
/// - 结束处理：清空运算符栈，组合成最终的AST
fn parse_binary_expr(
  expr : Expr,
  tokens : ArrayView[Token],
) -> (Expr, ArrayView[Token]) raise ParseError {
  let expr_stack : @stack.Stack[Expr] = @stack.of([expr])
  let op_stack : @stack.Stack[BinaryOp] = @stack.of([])
  loop tokens {
    // 处理运算符：通过优先级比较决定运算顺序
    [{ kind: BinaryOp(tok_binary_op) }, .. rest] => {
      let curr_op = BinaryOp::from_tok_binary_op(tok_binary_op)

      // 与栈顶运算符比较优先级
      // 如果栈顶优先级更高或相等，先处理栈顶运算
      loop op_stack.peek() {
        Some(top_op) if curr_op.precedence() <= top_op.precedence() => {
          // 立即组合：弹出运算符和两个表达式，创建BinaryExpr
          let right = expr_stack.pop().unwrap()
          let left = expr_stack.pop().unwrap()
          let op = op_stack.pop().unwrap()
          let binary_expr = Expr::new(ExprKind::BinaryExpr(op, left, right))
          expr_stack.push(binary_expr)
          continue op_stack.peek()
        }
        _ => break
      }

      // 当前运算符优先级更高，压栈等待后续操作数
      op_stack.push(curr_op)
      continue rest
    }

    // 处理操作数：解析后压入表达式栈
    tokens => {
      let (apply_expr, rest_tokens) = parse_apply_expr(tokens)
      let expr = Expr::new(ExprKind::ApplyExpr(apply_expr))
      expr_stack.push(expr)
      match rest_tokens {
        [{ kind: BinaryOp(_) }, ..] =>
          // 还有更多运算符，继续解析
          continue rest_tokens
        _ => {
          // 没有更多运算符，清空运算符栈，组合成最终结果
          loop op_stack.peek() {
            Some(_) => {
              // 弹出运算符和两个表达式，组合成BinaryExpr
              let right = expr_stack.pop().unwrap()
              let left = expr_stack.pop().unwrap()
              let op = op_stack.pop().unwrap()
              let binary_expr = Expr::new(ExprKind::BinaryExpr(op, left, right))
              expr_stack.push(binary_expr)
              continue op_stack.peek()
            }
            None => break
          }
          // 返回最终的AST和剩余token
          (expr_stack.pop().unwrap(), rest_tokens)
        }
      }
    }
  }
}

///|
/// 判断token是否为一元运算符
/// 支持：! (逻辑非), - (负号)
fn is_unary_op(token : Token) -> Bool {
  match token.kind {
    Not | BinaryOp(Sub) => true
    _ => false
  }
}

///|
/// 创建一元表达式节点
/// 将一元运算符应用到表达式上
fn unary_expr(token : Token, expr : Expr) -> Expr raise ParseError {
  match token.kind {
    Not => Expr::new(ExprKind::NotExpr(expr))
    BinaryOp(Sub) => Expr::new(ExprKind::NegExpr(expr))
    _ => raise ParseError("Expected Not or BinaryOp(Sub)")
  }
}

///|
/// 运算符优先级定义
/// 
/// 优先级规则（数值越大优先级越高）：
/// - 逻辑运算符：Or(1) < And(2)
/// - 比较运算符：Eq/NE(3) < 关系运算符(4)
/// - 位运算符：BitOr(5) < BitAnd(7)
/// - 位移运算符：ShiftLeft/ShiftRight(8)
/// - 算术运算符：Add/Sub(9) < Mul/Div/Mod(10)
/// 
/// 示例：1 + 2 * 3 中，* 优先级高于 +，所以先算 2 * 3
fn BinaryOp::precedence(self : Self) -> Int {
  match self {
    Or => 1
    And => 2
    Eq | NE => 3
    LT | GT | LE | GE => 4
    BitOr => 5
    BitAnd => 7
    ShiftLeft | ShiftRight => 8
    Add | Sub => 9
    Mul | Div | Mod => 10
  }
}
