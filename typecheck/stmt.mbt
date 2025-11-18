///|
pub(all) struct Stmt {
  kind : StmtKind
} derive(Show)

///|
pub(all) enum StmtKind {
  LetStmt(LetStmt)
  LetMutStmt(LetMutStmt)
  AssignStmt(AssignStmt)
  WhileStmt(WhileStmt)
  ExprStmt(Expr)
  ReturnStmt(Expr?)
  LocalFunction(LocalFunction)
} derive(Show)

///|
pub fn Context::check_stmt(
  self : Context,
  stmt : @parser.Stmt,
) -> Stmt raise TypeCheckError {
  match stmt.kind {
    @parser.StmtKind::LetStmt(let_stmt) => {
      let let_stmt = self.check_let_stmt(let_stmt)
      Stmt::{ kind: StmtKind::LetStmt(let_stmt) }
    }
    @parser.StmtKind::LetMutStmt(let_mut_stmt) => {
      let let_mut_stmt = self.check_let_mut_stmt(let_mut_stmt)
      Stmt::{ kind: StmtKind::LetMutStmt(let_mut_stmt) }
    }
    @parser.StmtKind::AssignStmt(assign_stmt) => {
      let assign_stmt = self.check_assign_stmt(assign_stmt)
      Stmt::{ kind: StmtKind::AssignStmt(assign_stmt) }
    }
    @parser.StmtKind::WhileStmt(while_stmt) => {
      let while_stmt = self.check_while_stmt(while_stmt)
      Stmt::{ kind: StmtKind::WhileStmt(while_stmt) }
    }
    @parser.StmtKind::ExprStmt(expr_stmt) => {
      let expr_stmt = self.check_expr(expr_stmt)
      Stmt::{ kind: StmtKind::ExprStmt(expr_stmt) }
    }
    @parser.StmtKind::ReturnStmt(return_stmt) => {
      guard self.current_func_ret_ty is Some(ret_ty) else {
        raise TypeCheckError("return: return statement outside of function")
      }
      let return_stmt = if return_stmt is Some(expr) {
        let expr = self.check_expr(expr)
        guard self.is_type_compatible(expr.ty, ret_ty) else {
          raise TypeCheckError(
            "return: type mismatch, '\{expr.ty}' and '\{ret_ty}'",
          )
        }
        Some(expr)
      } else {
        guard ret_ty is Unit else {
          raise TypeCheckError("return: return statement must be Unit")
        }
        None
      }
      Stmt::{ kind: StmtKind::ReturnStmt(return_stmt) }
    }
    @parser.StmtKind::LocalFunction(local_function) => {
      let local_function = self.check_local_function(local_function)
      Stmt::{ kind: StmtKind::LocalFunction(local_function) }
    }
  }
}
