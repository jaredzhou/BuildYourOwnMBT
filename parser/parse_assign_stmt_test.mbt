/// ================================================================================
/// # 组装！解析赋值语句
///
/// 万事俱备！我们已经分别实现了 `left_value` 和 `expr` 的解析器。
/// 现在，是时候将它们组装起来，完成**赋值语句（Assignment Statement）**的解析了。
///
/// ## 赋值语句的 EBNF 范式
///
/// 让我们再次回顾一下赋值语句的结构：
///
/// ```
/// assign_stmt ::= left_value assign_op expr ";"
/// ```
///
/// ## 🎯 你的任务：实现 `parse_assign_stmt`
///
/// 你的任务是在 `parser/assign_stmt.mbt` 中实现 `parse_assign_stmt` 函数。
///
/// 这个任务非常直接，它完美地体现了递归下降解析器的“组合”思想：
///
/// 1.  **解析左值：** 首先，调用你刚刚完成的 `parse_left_value` 函数来解析赋值符号左边的部分。
/// 2.  **解析赋值符号：** 接着，匹配一个赋值操作符（`=`、`+=` 等）。
/// 3.  **解析右值：** 然后，调用我们强大的 `parse_expr` 函数来解析赋值符号右边的表达式。
/// 4.  **结尾：** 最后，确保语句以分号 `;` 结尾。
///
/// 你看，我们之前所有的努力，都是为了在这一刻能够轻松地将各个部分组合在一起。
///
/// 加油，解析器的语句部分即将完成！
///
/// **阶段性测试：**
///
/// ```bash
/// moon test -p parser -f parse_assign_stmt_test.mbt
/// ```
/// ================================================================================

///|
test "Assign Stmt Parsing Test" {
  let code =
    #|obj.field1 = 42 ;
    #|matrix[1][2] += 3.14 ;
    #|arr[3][5].field -= arr[0][0] ;
    #|x *= 10 ;
    #|y /= 2 ;
    #|z %= 5 ;
  let tokens = @lexer.tokenize(code)
  let (a, tok_view) = parse_assign_stmt(tokens[:])
  assert_true(
    a.left_value.kind is FieldAccess(field_access, field_name) &&
    field_name is "field1" &&
    field_access.kind is Ident("obj") &&
    a.op is Assign &&
    a.expr.kind is ApplyExpr(expr_app) &&
    expr_app.kind is AtomExpr(expr_atom) &&
    expr_atom.kind is Int(42),
  )
  let (a, tok_view) = parse_assign_stmt(tok_view)
  assert_true(
    a.left_value.kind is ArrayAccess(array_access2, index_expr2) &&
    index_expr2.kind is ApplyExpr(index_app2) &&
    index_app2.kind is AtomExpr(index_atom2) &&
    index_atom2.kind is Int(2) &&
    array_access2.kind is ArrayAccess(array_access1, index_expr1) &&
    index_expr1.kind is ApplyExpr(index_app1) &&
    index_app1.kind is AtomExpr(index_atom1) &&
    index_atom1.kind is Int(1) &&
    array_access1.kind is Ident("matrix") &&
    a.op is PlusAssign &&
    a.expr.kind is ApplyExpr(expr_app2) &&
    expr_app2.kind is AtomExpr(expr_atom2) &&
    expr_atom2.kind is Double(3.14),
  )
  let (a, tok_view) = parse_assign_stmt(tok_view)
  assert_true(
    a.left_value.kind is FieldAccess(field_access2, field_name2) &&
    field_name2 is "field" &&
    field_access2.kind is ArrayAccess(array_access3, index_expr3) &&
    index_expr3.kind is ApplyExpr(index_app3) &&
    index_app3.kind is AtomExpr(index_atom3) &&
    index_atom3.kind is Int(5) &&
    array_access3.kind is ArrayAccess(array_access4, index_expr4) &&
    index_expr4.kind is ApplyExpr(index_app4) &&
    index_app4.kind is AtomExpr(index_atom4) &&
    index_atom4.kind is Int(3) &&
    array_access4.kind is Ident("arr") &&
    a.op is MinusAssign &&
    a.expr.kind is ApplyExpr(expr_app3) &&
    expr_app3.kind is ArrayAccess(expr_array_access, expr_index_expr) &&
    expr_index_expr.kind is ApplyExpr(expr_index_app) &&
    expr_index_app.kind is AtomExpr(expr_index_atom) &&
    expr_index_atom.kind is Int(0) &&
    expr_array_access.kind is ArrayAccess(expr_array_access2, expr_index_expr2) &&
    expr_index_expr2.kind is ApplyExpr(expr_index_app2) &&
    expr_index_app2.kind is AtomExpr(expr_index_atom2) &&
    expr_index_atom2.kind is Int(0) &&
    expr_array_access2.kind is AtomExpr(expr_array_atom) &&
    expr_array_atom.kind is Ident("arr"),
  )
  let (a, _) = parse_assign_stmt(tok_view)
  assert_true(
    a.left_value.kind is Ident("x") &&
    a.op is MultAssign &&
    a.expr.kind is ApplyExpr(expr_app4) &&
    expr_app4.kind is AtomExpr(expr_atom4) &&
    expr_atom4.kind is Int(10),
  )
}