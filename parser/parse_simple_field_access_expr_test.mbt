/// ================================================================================
/// # ApplyExpr 的终章：结构体字段访问
///
/// 我们已经完成了 `ApplyExpr` 的大部分功能，现在只剩下最后一种，也是非常重要的一种：
/// **结构体字段访问（Struct Field Access）**。
///
/// ## 字段访问语法
///
/// 字段访问的语法是通过点号 `.` 来访问一个结构体实例的成员：`my_struct.field_name`。
/// 这里的 `my_struct` 是一个 `ApplyExpr`，而 `field_name` 是一个标识符（`Lower` Token）。
///
/// ## 🎯 你的任务：在 `parse_apply_expr` 中处理 `.`
///
/// 我们的目标是最终完善 `parser/apply_expr.mbt` 中的 `parse_apply_expr` 函数，
/// 使其能够处理字段访问，并能够与数组索引、函数调用等无缝衔接。
///
/// **实现思路：**
///
/// 这部分逻辑可以完美地融入我们为处理数组索引和函数调用而构建的循环中。
///
/// 1.  **解析基础：** 函数首先解析出一个基础的 `ApplyExpr`。
///
/// 2.  **循环向后看：** 在循环中，检查基础表达式后面的 Token。
///
/// 3.  **匹配 `.`：**
///     *   如果下一个 Token 是 `.`，那么说明一个字段访问开始了。
///     *   跳过 `.`。
///     *   **特别注意：** 字段名必须是一个小写字母开头的标识符。所以，你需要检查紧跟在 `.` 后面的 Token 是否为 `TokenKind::Lower`。
///     *   如果匹配成功，提取出字段名（一个 `String`）。
///     *   现在，你拥有了“被访问的对象”（`object`）和“字段名”（`field`）。
///       用它们来创建一个新的、类型为 `FieldAccess` 的 `ApplyExpr`。
///
/// 4.  **链式访问：**
///     *   这个新的 `FieldAccess` 表达式会包裹住旧的 `ApplyExpr`。在下一次循环中，它又可以作为
///       `obj.field1.field2` 或 `obj.field[0]` 或 `obj.method()` 等更复杂链式操作的基础。
///
/// **阶段性测试：**
///
/// 完成后，运行以下命令来检验你的实现：
///
/// ```bash
/// moon test -p parser -f parse_simple_field_access_expr_test.mbt
/// ```
///
/// **祝贺你！完成这一步后，你的 `parse_apply_expr` 函数就彻底完工了。你已经构建了一个能够解析 MiniMoonBit 中所有复杂表达式组合的强大解析器！**
/// ================================================================================

///|
test "Simple Field Access Parsing Test" {
  let code =
    #|obj.field
    #|obj.nested.field
  let tokens = @lexer.tokenize(code)
  let (a, tok_view) = parse_apply_expr(tokens[:])
  assert_true(
    a.kind is ApplyExprKind::FieldAccess(obj_access, field) &&
    field == "field" &&
    obj_access.kind is ApplyExprKind::AtomExpr(atom_obj) &&
    atom_obj.kind is AtomExprKind::Ident("obj"),
  )
  let (a, _) = parse_apply_expr(tok_view)
  assert_true(
    a.kind is ApplyExprKind::FieldAccess(nested_access, field2) &&
    field2 == "field" &&
    nested_access.kind is ApplyExprKind::FieldAccess(obj_access2, field1) &&
    field1 == "nested" &&
    obj_access2.kind is ApplyExprKind::AtomExpr(atom_obj2) &&
    atom_obj2.kind is AtomExprKind::Ident("obj"),
  )
}