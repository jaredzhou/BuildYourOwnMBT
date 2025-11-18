/// ================================================================================
/// # 赋值的左侧：解析 LeftValue
///
/// 我们即将开始解析赋值语句（Assignment Statement），这是命令式编程的核心之一。
/// 在 `let` 语句中，我们是“声明并绑定”；而在赋值语句中，我们是“修改一个已存在的值”。
///
/// ## 赋值语句与 LeftValue
///
/// 赋值语句的结构如下：
///
/// ```
/// assign_stmt ::= left_value assign_op expr ";"
/// ```
///
/// 这里的 `assign_op` 包括 `=`、`+=` 等。
///
/// 关键在于 `left_value`（左值）。什么是左值？简单来说，就是**可以被放在赋值符号左边的东西**。
/// 并不是所有的表达式都可以是左值。例如，你可以写 `x = 1`，但不能写 `x + 1 = 2`。
///
/// 在 MiniMoonBit 中，合法的左值包括：
/// 1.  **变量：** `x`
/// 2.  **数组元素：** `arr[i]`
/// 3.  **结构体字段：** `obj.field`
/// 4.  **以及它们的组合：** `obj.arr[i].field`
///
/// ## 🎯 你的任务：实现 `parse_left_value`
///
/// 在解析完整的赋值语句之前，我们需要先在 `parser/left_value.mbt` 中实现 `parse_left_value` 函数，
/// 专门用于解析赋值符号左边的部分。
///
/// **实现思路：**
///
/// 仔细观察左值的构成，你会发现它和我们之前实现的 `ApplyExpr` 非常相似！
///
/// `ApplyExpr` 是 `atom_expr` 后面跟着一系列的 `(...)`、`[...]` 或 `.ident`。
/// 而 `LeftValue` 是一个 `ident` 后面跟着一系列的 `[...]` 或 `.ident`。
///
/// 它就像一个简化版的 `ApplyExpr` 解析器：
/// 1.  **起点：** `LeftValue` 必须以一个标识符（`ident`）开始。
/// 2.  **循环：** 在解析出标识符后，进入一个循环，向后检查是否存在 `[` 或 `.`。
/// 3.  **组合：** 如果存在，就解析对应的数组索引或字段访问，并用它**包裹**住之前解析出的 `LeftValue`，形成一个新的 `LeftValue`。
/// 4.  **结束：** 循环直到后面再也没有 `[` 或 `.` 为止。
///
/// 相信这个过程对你来说已经非常熟悉了。加油！
///
/// **阶段性测试：**
///
/// ```bash
/// moon test -p parser -f parse_left_value_test.mbt
/// ```
/// ================================================================================

///|
test "LeftValue Parsing Test" {
  let code =
    #|obj.field1[0] ;
    #|matrix[1][2] ;
    #|arr[3][5].field
  let tokens = @lexer.tokenize(code)
  let (a, tok_view) = parse_left_value(tokens[:])
  assert_true(
    a.kind is ArrayAccess(array_access, index_expr) &&
    index_expr.kind is ApplyExpr(index_app) &&
    index_app.kind is AtomExpr(index_atom) &&
    index_atom.kind is Int(0) &&
    array_access.kind is FieldAccess(field_access, field_name) &&
    field_name is "field1" &&
    field_access.kind is Ident("obj"),
  )
  let (a, tok_view) = parse_left_value(tok_view[1:])
  assert_true(
    a.kind is ArrayAccess(array_access2, index_expr2) &&
    index_expr2.kind is ApplyExpr(index_app2) &&
    index_app2.kind is AtomExpr(index_atom2) &&
    index_atom2.kind is Int(2) &&
    array_access2.kind is ArrayAccess(array_access1, index_expr1) &&
    index_expr1.kind is ApplyExpr(index_app1) &&
    index_app1.kind is AtomExpr(index_atom1) &&
    index_atom1.kind is Int(1) &&
    array_access1.kind is Ident("matrix"),
  )
  let (a, _) = parse_left_value(tok_view[1:])
  assert_true(
    a.kind is FieldAccess(field_access2, field_name2) &&
    field_name2 is "field" &&
    field_access2.kind is ArrayAccess(array_access3, index_expr3) &&
    index_expr3.kind is ApplyExpr(index_app3) &&
    index_app3.kind is AtomExpr(index_atom3) &&
    index_atom3.kind is Int(5) &&
    array_access3.kind is ArrayAccess(array_access4, index_expr4) &&
    index_expr4.kind is ApplyExpr(index_app4) &&
    index_app4.kind is AtomExpr(index_atom4) &&
    index_atom4.kind is Int(3) &&
    array_access4.kind is Ident("arr"),
  )
}