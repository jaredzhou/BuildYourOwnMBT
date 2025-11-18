/// ================================================================================
/// # ApplyExpr 的再扩展：函数调用
///
/// 我们已经成功地为 `ApplyExpr` 添加了数组索引的功能。现在，让我们来完成它的最后一块拼图：
/// **函数调用（Function Calls）**。
///
/// ## 函数调用语法
///
/// 函数调用的语法是 `function_name(argument1, argument2, ...)`。
/// 这里的 `function_name` 是一个 `ApplyExpr`，而括号内的参数列表是一个由逗号分隔的 `Expr` 列表。
///
/// 你会发现，这个参数列表的结构与我们之前解析过的元组（Tuple）和数组字面量（Array Literal）几乎完全一样！
///
/// ## 🎯 你的任务：在 `parse_apply_expr` 中处理 `(...)`
///
/// 我们的目标是继续扩展 `parser/apply_expr.mbt` 中的 `parse_apply_expr` 函数，
/// 使其在解析完一个基础表达式后，能够继续检查并解析函数调用。
///
/// **实现思路：**
///
/// 这部分逻辑与解析数组索引非常相似，可以放在同一个循环中处理。
///
/// 1.  **解析基础：** 函数首先解析出一个基础的 `ApplyExpr`。
///
/// 2.  **循环向后看：** 进入一个循环，检查基础表达式后面的 Token。
///
/// 3.  **匹配 `(`：**
///     *   如果下一个 Token 是 `(`，那么说明一个函数调用开始了。
///     *   跳过 `(`。
///     *   接下来，你需要解析括号内的参数列表。这是一个由逗号分隔的 `Expr` 列表。
///       这个逻辑和解析元组/数组的内部非常相似，你可以考虑将这部分逻辑抽象成一个可复用的辅助函数，
///       例如 `parse_expr_list`，它接收 Token，返回一个 `Array[Expr]` 和剩余的 Token。
///     *   确保参数列表后面紧跟着一个 `)`，并跳过它。
///     *   现在，你拥有了“被调用的函数”（`callee`）和“参数列表”（`args`）。
///       用它们来创建一个新的、类型为 `Call` 的 `ApplyExpr`。
///
/// 4.  **结合与循环：**
///     *   这个新的 `Call` 表达式会包裹住旧的 `ApplyExpr`。在下一次循环中，这个新的 `ApplyExpr`
///       又可以作为更外层调用（例如 `foo(1)(2)`）或者数组索引（例如 `foo(1)[2]`）的基础。
///
/// **阶段性测试：**
///
/// 完成后，运行以下命令来检验你的实现：
///
/// ```bash
/// moon test -p parser -f parse_simple_call_expr_test.mbt
/// ```
///
/// **祝贺你！完成这一步后，你的 `ApplyExpr` 解析器就功能完备了，能够处理复杂的表达式组合！**
/// ================================================================================

///|
test "Simple Call Expr Parsing Test" {
  let code =
    #|foo()
    #|bar(42, true)
    #|qux(1 + 3)
  let tokens = @lexer.tokenize(code)
  let (a, tok_view) = parse_apply_expr(tokens[:])
  assert_true(
    a.kind is ApplyExprKind::Call(callee, args) &&
    args is [] &&
    callee.kind is AtomExpr(callee_atom) &&
    callee_atom.kind is AtomExprKind::Ident("foo"),
  )
  let (a, tok_view) = parse_apply_expr(tok_view)
  assert_true(
    a.kind is ApplyExprKind::Call(callee, args) &&
    args is [arg1, arg2] &&
    arg1.kind is ApplyExpr(arg1_app) &&
    arg1_app.kind is AtomExpr(arg1_atom) &&
    arg1_atom.kind is AtomExprKind::Int(42) &&
    arg2.kind is ApplyExpr(arg2_app) &&
    arg2_app.kind is AtomExpr(arg2_atom) &&
    arg2_atom.kind is AtomExprKind::Bool(true) &&
    callee.kind is AtomExpr(callee_atom) &&
    callee_atom.kind is AtomExprKind::Ident("bar"),
  )
  let (a, _) = parse_apply_expr(tok_view)
  assert_true(
    a.kind is ApplyExprKind::Call(callee, args) &&
    args is [arg1] &&
    arg1.kind is BinaryExpr(Add, left, right) &&
    left.kind is ApplyExpr(left_app) &&
    left_app.kind is AtomExpr(left_atom) &&
    left_atom.kind is AtomExprKind::Int(1) &&
    right.kind is ApplyExpr(right_app) &&
    right_app.kind is AtomExpr(right_atom) &&
    right_atom.kind is AtomExprKind::Int(3) &&
    callee.kind is AtomExpr(callee_atom) &&
    callee_atom.kind is AtomExprKind::Ident("qux"),
  )
}