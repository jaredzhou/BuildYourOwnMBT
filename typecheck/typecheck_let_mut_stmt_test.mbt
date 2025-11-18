/// ================================================================================
/// # 类型检查语句：let mut
///
/// 我们已经能够检查各种复杂的表达式了。现在，是时候将目光转向**语句（Statements）**的类型检查了。
///
/// 语句与表达式的核心区别在于：语句不一定有“值”，但它们通常会产生**副作用（Side Effects）**。
/// 在类型检查中，最重要的副作用就是**改变类型环境（Type Environment）**。
///
/// `let mut` 语句就是一个典型的例子，它会向当前作用域引入一个新的可变变量。
///
/// ## 🎯 你的任务：实现 `check_let_mut_stmt`
///
/// 你的任务是在 `typecheck/let_mut_stmt.mbt` 文件中实现 `Context::check_let_mut_stmt` 函数。
///
/// ### 💡 实现思路
///
/// `check_let_mut_stmt` 的工作流程如下：
///
/// 1.  **检查表达式：** 首先，调用 `self.check_expr` 来确定 `=` 右侧表达式的类型。
///
/// 2.  **处理类型注解（如果存在）：**
///     *   `let mut` 语句可能带有显式的类型注解，例如 `let mut x: Double = ...`。
///     *   如果存在类型注解，你需要调用 `self.check_parser_type` 来转换它。
///     *   然后，**关键一步**：使用 `self.is_type_compatible` 验证表达式的类型是否与注解的类型兼容。如果不兼容，则应抛出类型错误。
///
/// 3.  **确定变量类型：**
///     *   如果存在类型注解，变量的类型就是该注解的类型。
///     *   如果不存在，变量的类型就从表达式的类型中**推断**出来。
///
/// 4.  **更新类型环境：**
///     *   这是最重要的一步！一旦确定了新变量的名称和类型，你必须将它添加到类型环境 `self.type_env` 中。
///     *   在添加到环境时，请务必标记该类型为**可变的（mutable: true）**。这对于后续的赋值语句检查至关重要。
///
/// ### 🤔 深入思考：空数组的类型推断
///
/// 本次挑战的测试用例包含 `let mut z = []`。
///
/// > 当我们看到一个空数组时，它的元素类型是什么？`Int`? `String`?
///
/// 在这一刻，我们**无法知道**。这就是**类型变量（Type Variable）**登场的时机。
/// 当遇到无法立即确定的类型时，我们可以创建一个临时的“占位符”类型，例如 `Array(TypeVar(0))`。
///
/// 在后续代码中，当我们第一次对 `z` 进行操作时（例如 `z.push(3.14)`），我们就可以将 `TypeVar(0)` 的实际类型“绑定”为 `Double`。
/// 这就是类型推断的核心思想之一。你的 `check_array_expr` 函数可能需要支持这种行为。
///
/// ---
///
/// **阶段性测试：**
///
/// ```bash
/// moon test -p typecheck -f typecheck_let_mut_stmt_test.mbt
/// ```
/// ================================================================================

///|
test "Let Mut Stmt Type Check" {
  let code =
    #|let mut x : Double = 42.0;
    #|let mut y = 10;
    #|let mut z = [];
    #|let _ = z.push(3.14);
    #|let _ = z.push("Hello"); // Should fail
  let ctx = Context::new()
  // Parse
  let tokens = @lexer.tokenize(code)
  // Type check for `let mut x : Double = 42.0;`
  let (let_mut_stmt1, tok_view) = @parser.parse_let_mut_stmt(tokens[:])
  let checked_let_mut_stmt1 = ctx.check_let_mut_stmt(let_mut_stmt1)
  assert_true(checked_let_mut_stmt1.ty.kind is Double)
  // Type check for `let mut y = 10;`
  let (let_mut_stmt2, tok_view) = @parser.parse_let_mut_stmt(tok_view)
  let checked_let_mut_stmt2 = ctx.check_let_mut_stmt(let_mut_stmt2)
  assert_true(checked_let_mut_stmt2.ty.kind is Int)
  // Type check for `let mut z = [];`
  let (let_mut_stmt3, tok_view) = @parser.parse_let_mut_stmt(tok_view)
  let checked_let_mut_stmt3 = ctx.check_let_mut_stmt(let_mut_stmt3)
  assert_true(checked_let_mut_stmt3.ty.kind is Array(TypeVar(_)))
  // Type check for `let _ = z.push(3.14);`
  // Parse Let Stmt
  let (let_stmt4, tok_view) = @parser.parse_let_stmt(tok_view)
  let checked_let_stmt4 = ctx.check_let_stmt(let_stmt4)
  assert_true(checked_let_stmt4.ty is Unit)
  println(ctx.type_vars.get(0))
  println(ctx.lookup_type("z"))
  assert_true(ctx.lookup_type("z") is Some({ kind: Array(Double), .. }))
  // Type check for `let _ = z.push("Hello");` - Should fail
  let (let_stmt5, _) = @parser.parse_let_stmt(tok_view)
  let check_result = try? ctx.check_let_stmt(let_stmt5)
  assert_true(check_result is Err(_))
}
