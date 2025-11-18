/// ================================================================================
/// # 终极挑战：类型检查局部函数与闭包
///
/// 欢迎来到类型检查阶段最具挑战性、也最见功力的部分：**检查局部函数（Local Functions）**。
///
/// 与必须明确标注所有类型的顶层函数不同，局部函数允许省略类型，这就要求我们的编译器具备真正的**类型推断**能力。
///
/// ## 🎯 你的任务：实现 `check_local_function`
///
/// 你的任务是在 `typecheck/local_function.mbt` 文件中实现 `Context::check_local_function` 函数。
///
/// ### 💡 实现思路：立即检查与合一
///
/// 检查一个局部函数 `fn f(a, b: T) { ... }` 的过程如下：
///
/// 1.  **创建函数类型：**
///     *   遍历函数的参数列表。
///     *   如果参数有类型注解（如 `b: T`），则转换该类型。
///     *   如果参数没有类型注解（如 `a`），则**创建一个新的类型变量 `TypeVar`** 作为其类型的占位符。
///     *   对返回值执行同样的操作：有注解则使用，无注解则创建 `TypeVar`。
///     *   将这些参数类型和返回类型组合成一个 `Function` 类型。例如 `fn f(a, b: Int)` 的类型就是 `Function([TypeVar(0), Int], TypeVar(1))`。
///
/// 2.  **更新环境（临时）：**
///     *   将这个新创建的、可能包含 `TypeVar` 的函数类型，与其名字 `f` 一起，添加到**当前**的类型环境中。这使得函数可以递归地调用自己。
///
/// 3.  **检查函数体（立即执行！）：**
///     *   **进入新作用域：** 调用 `enter_scope()`。
///     *   **设置返回类型：** 将 `Context` 的 `current_func_ret_ty` 设置为刚刚创建的函数返回类型（可能是 `TypeVar`）。
///     *   **添加参数到环境：** 将所有参数（包括类型为 `TypeVar` 的参数）添加到这个新的作用域中。
///     *   **检查函数体：** 调用 `check_block_expr` 检查函数体。在检查过程中，`is_type_compatible` 会被大量调用，驱动类型变量的**合一**（Unification），从而推断出具体类型。例如，如果函数体中有 `a > b`，那么 `a` 和 `b` 的类型变量就会被合一。
///     *   **验证返回类型：** 检查函数体的最终类型是否与函数的返回类型兼容。
///     *   **离开作用域：** 调用 `exit_scope()`。
///
/// ---
///
/// **阶段性测试：**
///
/// ```bash
/// moon test -p typecheck -f typecheck_local_func_test.mbt
/// ```
/// ================================================================================

///|
test "Local Function Type Check Test" {
  let code =
    #|fn max(a, b) {
    #|  if a > b { a } else { b }
    #|}
    #|
    #|let _ = max(10, 20);
    #|let _ = max(1.0, 2.0); // This should raise a type error
  let ctx = Context::new()
  // Parse
  let tokens = @lexer.tokenize(code)
  let (local_func, tok_view) = @parser.parse_local_function(tokens[:])
  // TypeCheck
  println("typecheck local function start")
  let _ = ctx.check_local_function(local_func)
  println("typecheck local function done")
  // parse and check let statement
  let (let_stmt, tok_view) = @parser.parse_let_stmt(tok_view)
  let let_stmt = ctx.check_let_stmt(let_stmt)
  assert_true(let_stmt.ty is Int)
  let (let_stmt2, _) = @parser.parse_let_stmt(tok_view)
  let let_stmt2 = try? ctx.check_let_stmt(let_stmt2)
  assert_true(let_stmt2 is Err(_))
}
