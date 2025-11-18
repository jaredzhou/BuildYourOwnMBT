///|
pub(all) enum KnfLeftValue {
  Ident(Name)
  ArrayAcc(Name, Name)
  FieldAcc(Name, String)
}

///|
pub fn Context::assign_stmt_to_knf(
  self : Context,
  assign_stmt : @typecheck.AssignStmt,
) -> Array[KnfStmt] raise KnfTransformError {
  let stmts = []
  //左值转表达式
  let (left_value_stmts, left_value_expr) = self.left_value_to_knf(
    assign_stmt.left_value,
  )
  stmts.append(left_value_stmts)
  //表达式转换
  let (expr_stmts, expr_knf) = self.expr_to_knf(assign_stmt.expr)
  stmts.append(expr_stmts)
  //根据op在进行一些操作
  let expr_knf = if assign_stmt.op is Assign {
    expr_knf
  } else {
    let left_value_name = self.expr_to_knf_name(
      left_value_expr,
      self.type_to_knf(assign_stmt.left_value.ty),
      stmts,
    )
    let expr_ty = self.typekind_to_knf(assign_stmt.expr.ty)
    let expr_name = self.expr_to_knf_name(expr_knf, expr_ty, stmts)
    let expr_knf = match assign_stmt.op {
      PlusAssign => Binary(Add, left_value_name, expr_name)
      MinusAssign => Binary(Sub, left_value_name, expr_name)
      MultAssign => Binary(Mul, left_value_name, expr_name)
      DivAssign => Binary(Div, left_value_name, expr_name)
      ModAssign => Binary(Mod, left_value_name, expr_name)
      _ =>
        raise KnfTransformError(
          "Unsupported assign op: \{assign_stmt.op.to_string()}",
        )
    }
    let temp_name = self.add_temp(expr_ty)
    stmts.push(KnfStmt::Let(temp_name, expr_ty, expr_knf))
    Ident(temp_name)
  }
  match left_value_expr {
    Ident(name) => {
      stmts.push(KnfStmt::Assign(name, expr_knf))
      stmts
    }
    ArrayAccess(left_value_name, index_name) => {
      stmts.push(KnfStmt::ArrayPut(left_value_name, index_name, expr_knf))
      stmts
    }
    FieldAccess(left_value_name, field) => {
      println("before value_name: \{stmts}")
      // let value_name = self.expr_to_knf_name(
      //   expr_knf,
      //   self.typekind_to_knf(assign_stmt.expr.ty),
      //   stmts,
      // )
      let value_ty = self.typekind_to_knf(assign_stmt.expr.ty)
      let value_name = self.add_temp(value_ty)
      stmts.push(KnfStmt::Let(value_name, value_ty, expr_knf))
      stmts.push(KnfStmt::StructFieldSet(left_value_name, field, value_name))
      stmts
    }
    _ =>
      raise KnfTransformError(
        "Unsupported left value kind: \{left_value_expr.to_string()}",
      )
  }
}

//外层左值, 全部转表达式

///|
fn Context::left_value_to_knf(
  self : Context,
  left_value : @typecheck.LeftValue,
) -> (Array[KnfStmt], KnfExpr) raise KnfTransformError {
  let stmts = []
  match left_value.kind {
    Ident(name) => {
      guard self.lookup_name(name) is Some((name, _)) else {
        raise KnfTransformError("name not found: \{name}")
      }
      (stmts, Ident(name))
    }
    ArrayAccess(left_value, index) => {
      let (left_value_stmts, left_value_expr) = self.left_value_to_knf(
        left_value,
      )
      stmts.append(left_value_stmts)
      let left_value_name = self.expr_to_knf_name(
        left_value_expr,
        self.type_to_knf(left_value.ty),
        stmts,
      )
      let (index_stmts, index_expr) = self.expr_to_knf(index)
      stmts.append(index_stmts)
      let index_name = self.expr_to_knf_name(
        index_expr,
        self.typekind_to_knf(index.ty),
        stmts,
      )
      (stmts, ArrayAccess(left_value_name, index_name))
    }
    FieldAccess(left_value, field) => {
      let (left_value_stmts, left_value_expr) = self.left_value_to_knf(
        left_value,
      )
      stmts.append(left_value_stmts)
      let left_value_ty = self.type_to_knf(left_value.ty)
      let left_value_name = self.expr_to_knf_name(
        left_value_expr, left_value_ty, stmts,
      )
      (stmts, FieldAccess(left_value_name, field))
    }
  }
}
