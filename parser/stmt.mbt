///|
pub(all) struct Stmt {
  kind : StmtKind
} derive(Show, Eq)

///|
pub(all) enum StmtKind {
  LetStmt(LetStmt)
  LetMutStmt(LetMutStmt)
  AssignStmt(AssignStmt)
  WhileStmt(WhileStmt)
  ExprStmt(Expr)
  ReturnStmt(Expr?)
  LocalFunction(LocalFunction)
} derive(Show, Eq)

///|
fn parse_expr_stmt(
  tokens : ArrayView[Token],
) -> (Stmt, ArrayView[Token]) raise ParseError {
  let (expr, rest) = parse_expr(tokens)
  match rest {
    [{ kind: Symbol(";") }, .. rest] =>
      (Stmt::{ kind: StmtKind::ExprStmt(expr) }, rest)
    [{ kind: Bracket('}') }, ..] =>
      (Stmt::{ kind: StmtKind::ExprStmt(expr) }, rest)
    _ => raise ParseError("Unexpected token: \{rest[0]}")
  }
}

///|
pub fn parse_stmt(
  tokens : ArrayView[Token],
) -> (Stmt, ArrayView[Token]) raise ParseError {
  match tokens {
    [{ kind: Keyword(Let) }, { kind: Keyword(Mut) }, ..] as tokens => {
      let (stmt, rest) = parse_let_mut_stmt(tokens)
      (Stmt::{ kind: StmtKind::LetMutStmt(stmt) }, rest)
    }
    [{ kind: Keyword(Let) }, ..] as tokens => {
      let (stmt, rest) = parse_let_stmt(tokens)
      (Stmt::{ kind: StmtKind::LetStmt(stmt) }, rest)
    }
    [{ kind: Keyword(Return) }, .. rest] => {
      let (expr, rest) = if rest is [{ kind: Symbol(";") }, .. rest] {
        (None, rest)
      } else {
        let (expr, rest) = parse_expr(rest)
        guard rest is [{ kind: Symbol(";") }, .. rest] else {
          raise ParseError("Unexpected token: \{rest[0]}")
        }
        (Some(expr), rest)
      }
      (Stmt::{ kind: StmtKind::ReturnStmt(expr) }, rest)
    }
    [{ kind: Keyword(While) }, ..] as tokens => {
      let (stmt, rest) = parse_while_stmt(tokens)
      (Stmt::{ kind: StmtKind::WhileStmt(stmt) }, rest)
    }
    [{ kind: Keyword(Fn) }, ..] as tokens => {
      let (stmt, rest) = parse_local_function(tokens)
      (Stmt::{ kind: StmtKind::LocalFunction(stmt) }, rest)
    }
    tokens =>
      // 检查是否可能是左值（标识符开头）
      match tokens {
        [{ kind: Lower(_) }, ..] => {
          // 尝试解析左值
          let (_, rest) = parse_left_value(tokens)
          match rest {
            [{ kind: AssignOp(_) }, ..] => {
              let (stmt, rest) = parse_assign_stmt(tokens)
              (Stmt::{ kind: StmtKind::AssignStmt(stmt) }, rest)
            }
            _ => parse_expr_stmt(tokens)
          }
        }
        _ => parse_expr_stmt(tokens)
      }
  }
}
