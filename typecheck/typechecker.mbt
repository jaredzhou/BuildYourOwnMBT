///|
pub fn typecheck(program : @parser.Program) -> Program raise TypeCheckError {
  let ctx = Context::new()
  ctx.type_env.set("print_int", Type::{
    kind: Function([Int], Unit),
    mutable: false,
  })
  ctx.func_types.set("print_int", Function([Int], Unit))
  let checked_program = ctx.check_program(program)
  ctx.substitute_type_var(checked_program)
}

///|
pub fn Context::substitute_type_var(
  self : Context,
  program : Program,
) -> Program raise TypeCheckError {
  let top_lets = program.top_lets.map((name, top_let) => TopLet::{
    name,
    ty: self.deref_type_kind(top_let.ty),
    expr: self.deref_expr(top_let.expr),
  })
  let top_functions = program.top_functions.map((_, top_function) => TopFunction::{
    fname: top_function.fname,
    param_list: top_function.param_list,
    ret_ty: self.deref_type_kind(top_function.ret_ty),
    body: self.deref_block_expr(top_function.body),
  })
  Program::{ struct_defs: program.struct_defs, top_lets, top_functions }
}

///|
fn Context::deref_type_kind(self : Context, ty : TypeKind) -> TypeKind {
  match ty {
    TypeVar(id) => self.deref_type_var(id)
    Array(elem_type) => Array(self.deref_type_kind(elem_type))
    Tuple(types) => Tuple(types.map(ty => self.deref_type_kind(ty)))
    Function(params, ret) =>
      Function(
        params.map(ty => self.deref_type_kind(ty)),
        self.deref_type_kind(ret),
      )
    _ => ty
  }
}

///|
fn Context::deref_type(self : Context, ty : Type) -> Type {
  Type::{ kind: self.deref_type_kind(ty.kind), mutable: ty.mutable }
}

///|
fn Context::deref_expr(self : Context, expr : Expr) -> Expr {
  let kind : ExprKind = match expr.kind {
    ApplyExpr(apply_expr) => ApplyExpr(self.deref_apply_expr(apply_expr))
    BlockExpr(block_expr) => BlockExpr(self.deref_block_expr(block_expr))
    NotExpr(expr) => NotExpr(self.deref_expr(expr))
    NegExpr(expr) => NegExpr(self.deref_expr(expr))
    BinaryExpr(bin_op, left_expr, right_expr) =>
      BinaryExpr(
        bin_op,
        self.deref_expr(left_expr),
        self.deref_expr(right_expr),
      )
    IfExpr(if_expr) => IfExpr(self.deref_if_expr(if_expr))
  }
  Expr::{ kind, ty: self.deref_type_kind(expr.ty) }
}

///|
fn Context::deref_if_expr(self : Context, if_expr : IfExpr) -> IfExpr {
  IfExpr::{
    cond: self.deref_expr(if_expr.cond),
    then_block: self.deref_block_expr(if_expr.then_block),
    else_block: if_expr.else_block.map(else_block => match else_block {
      Left(if_expr) => Left(self.deref_if_expr(if_expr))
      Right(block_expr) => Right(self.deref_block_expr(block_expr))
    }),
    ty: self.deref_type_kind(if_expr.ty),
  }
}

///|
fn Context::deref_apply_expr(
  self : Context,
  apply_expr : ApplyExpr,
) -> ApplyExpr {
  let kind = match apply_expr.kind {
    AtomExpr(atom_expr) =>
      AtomExpr(AtomExpr::{
        kind: self.deref_atom_expr(atom_expr.kind),
        ty: self.deref_type_kind(atom_expr.ty),
      })
    ArrayAccess(apply_expr, index_expr) =>
      ArrayAccess(
        self.deref_apply_expr(apply_expr),
        self.deref_expr(index_expr),
      )
    FieldAccess(apply_expr, field_name) =>
      FieldAccess(self.deref_apply_expr(apply_expr), field_name)
    Call(apply_expr, args) =>
      Call(
        self.deref_apply_expr(apply_expr),
        args.map(arg => self.deref_expr(arg)),
      )
  }
  ApplyExpr::{ kind, ty: self.deref_type_kind(apply_expr.ty) }
}

///|
fn Context::deref_block_expr(
  self : Context,
  block_expr : BlockExpr,
) -> BlockExpr {
  BlockExpr::{
    stmts: block_expr.stmts.map(stmt => self.deref_stmt(stmt)),
    ty: self.deref_type_kind(block_expr.ty),
  }
}

///|
fn Context::deref_stmt(self : Context, stmt : Stmt) -> Stmt {
  let kind = match stmt.kind {
    StmtKind::LetStmt(let_stmt) =>
      StmtKind::LetStmt(LetStmt::{
        pattern: let_stmt.pattern,
        ty: self.deref_type_kind(let_stmt.ty),
        expr: self.deref_expr(let_stmt.expr),
      })
    StmtKind::LetMutStmt(let_mut_stmt) =>
      StmtKind::LetMutStmt(LetMutStmt::{
        name: let_mut_stmt.name,
        ty: self.deref_type(let_mut_stmt.ty),
        expr: self.deref_expr(let_mut_stmt.expr),
      })
    StmtKind::AssignStmt(assign_stmt) =>
      StmtKind::AssignStmt(AssignStmt::{
        left_value: self.deref_left_value(assign_stmt.left_value),
        op: assign_stmt.op,
        expr: self.deref_expr(assign_stmt.expr),
      })
    StmtKind::WhileStmt(while_stmt) =>
      StmtKind::WhileStmt(WhileStmt::{
        cond: self.deref_expr(while_stmt.cond),
        body: self.deref_block_expr(while_stmt.body),
      })
    StmtKind::ExprStmt(expr) => StmtKind::ExprStmt(self.deref_expr(expr))
    StmtKind::ReturnStmt(expr) =>
      StmtKind::ReturnStmt(expr.map(expr => self.deref_expr(expr)))
    StmtKind::LocalFunction(local_function) =>
      StmtKind::LocalFunction(LocalFunction::{
        fname: local_function.fname,
        param_list: local_function.param_list.map(param => (
          param.0,
          self.deref_type(param.1),
        )),
        ret_ty: self.deref_type(local_function.ret_ty),
        body: self.deref_block_expr(local_function.body),
      })
  }
  Stmt::{ kind, }
}

///|
fn Context::deref_left_value(
  self : Context,
  left_value : LeftValue,
) -> LeftValue {
  let kind = match left_value.kind {
    LeftValueKind::Ident(name) => LeftValueKind::Ident(name)
    LeftValueKind::ArrayAccess(left_value, index_expr) =>
      LeftValueKind::ArrayAccess(
        self.deref_left_value(left_value),
        self.deref_expr(index_expr),
      )
    LeftValueKind::FieldAccess(left_value, field_name) =>
      LeftValueKind::FieldAccess(self.deref_left_value(left_value), field_name)
  }
  LeftValue::{ kind, ty: self.deref_type(left_value.ty) }
}

///|
fn Context::deref_atom_expr(
  self : Context,
  atom_expr : AtomExprKind,
) -> AtomExprKind {
  match atom_expr {
    Paren(expr) => Paren(self.deref_expr(expr))
    Tuple(exprs) => Tuple(exprs.map(expr => self.deref_expr(expr)))
    Array(exprs) => Array(exprs.map(expr => self.deref_expr(expr)))
    ArrayMake(size_expr, init_expr) =>
      ArrayMake(self.deref_expr(size_expr), self.deref_expr(init_expr))
    StructConstruct(sc_expr) =>
      StructConstruct(StructConstructExpr::{
        name: sc_expr.name,
        fields: sc_expr.fields.map(field => (field.0, self.deref_expr(field.1))),
      })
    _ => atom_expr
  }
}
