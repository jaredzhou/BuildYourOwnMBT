/// ================================================================================
/// # 编译器“开洞”：解析特殊的 `Array::make` 语法
///
/// 在设计一门语言时，有时我们会遇到一些无法通过通用语法规则优雅表达的结构。
/// 这时，编译器开发者会选择“开一个洞”，为这种特殊情况编写专门的解析逻辑。
///
/// `Array::make(size, init)` 就是 MiniMoonBit 中的一个典型例子。
/// 它看起来像一个函数调用，但实际上是一种特殊的、内置于语言核心的数组创建语法。
/// 你可以把它类比于 C 语言中的 `int arr[n];`，这同样不是一个普通的函数调用，
/// 而是需要编译器特殊处理的语法结构。
///
/// ## 🎯 你的任务：在 `parse_atom_expr` 中处理 `Array::make`
///
/// 我们的目标是在 `atom_expr.mbt` 中，通过一个新的辅助函数 `parse_array_make_expr`
/// 来实现对这个特殊语法的解析。`parse_atom_expr` 将在遇到 `Array` 关键字时调用这个新函数。
///
/// **实现思路：**
///
/// 1.  **入口：** 当 `parse_atom_expr` 遇到 `Array` 这个 `Upper` 类型的 Token 时，
///     它应该将解析工作委托给 `parse_array_make_expr`。
///
/// 2.  **`parse_array_make_expr` 的逻辑：**
///     *   这个函数需要进行一次精确的“模式匹配”，确保接下来的 Token 序列是 `::`，`make`，和 `(`。
///       如果不是，那么这可能是一个普通的以 `Array` 开头的类型名，应该立即报错或交由其他逻辑处理（在我们的例子中，直接报错）。
///     *   跳过 `Array::make(` 这一固定序列。
///     *   调用 `parse_expr` 来解析数组的**大小（size）**。
///     *   确保下一个 Token 是一个逗号 `,`，并跳过它。
///     *   再次调用 `parse_expr` 来解析数组的**初始值（init）**。
///     *   确保最后一个 Token 是一个右括号 `)`，并跳过它。
///     *   最后，将解析出的 `size` 和 `init` 两个表达式组装成一个 `ArrayMake` 节点。
///
/// 这种为特定语法“开洞”的做法，在真实的编译器中非常常见，它体现了语言设计在一致性与实用性之间的权衡。
///
/// **阶段性测试：**
///
/// 完成后，运行以下命令来检验你的实现：
///
/// ```bash
/// moon test -p parser -f parse_array_make_test.mbt
/// ```
///
/// **祝你顺利！你正在学习编译器开发中非常实用的一个技巧！**
/// ================================================================================

///|
test "Array Make Expr Parsing Test" {
  let code =
    #|Array::make(10, 0)
    #|Array::make(5, true)
  let tokens = @lexer.tokenize(code)
  let (a, tok_view) = parse_atom_expr(tokens[:])
  assert_true(
    a.kind is AtomExprKind::ArrayMake(size_expr, init_expr) &&
    size_expr.kind is ApplyExpr(app1) &&
    app1.kind is AtomExpr(atom1) &&
    atom1.kind is Int(10) &&
    init_expr.kind is ApplyExpr(app2) &&
    app2.kind is AtomExpr(atom2) &&
    atom2.kind is Int(0),
  )
  let (a, _) = parse_atom_expr(tok_view)
  assert_true(
    a.kind is AtomExprKind::ArrayMake(size_expr, init_expr) &&
    size_expr.kind is ApplyExpr(app1) &&
    app1.kind is AtomExpr(atom1) &&
    atom1.kind is Int(5) &&
    init_expr.kind is ApplyExpr(app2) &&
    app2.kind is AtomExpr(atom2) &&
    atom2.kind is Bool(true),
  )
}