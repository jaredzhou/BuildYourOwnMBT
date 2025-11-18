/// ================================================================================
/// # 类型检查语句：顶层 let
///
/// 除了函数内部的 `let mut`，我们的语言还支持在顶层（全局作用域）使用 `let` 来定义全局常量。
/// 对它的类型检查与 `let mut` 非常相似，但有一个关键的区别。
///
/// ## 🎯 你的任务：实现 `check_top_let`
///
/// 你的任务是在 `typecheck/top_let.mbt` 文件中实现 `Context::check_top_let` 函数。
///
/// ### 💡 实现思路
///
/// `check_top_let` 的逻辑几乎与 `check_let_mut_stmt` 完全相同：
///
/// 1.  检查 `=` 右侧表达式的类型。
/// 2.  如果存在类型注解，则验证其与表达式类型是否兼容。
/// 3.  将新变量的名称和类型添加到类型环境 `self.type_env` 中。
///
/// **唯一的区别在于：**
///
/// > 通过顶层 `let` 定义的变量是**不可变的（immutable）**。
/// > 因此，在将它添加到类型环境时，你必须将其标记为 `mutable: false`。
///
/// 这确保了编译器在后续的检查中，如果遇到试图修改该变量的赋值语句，能够正确地抛出错误。
///
/// ---
///
/// **阶段性测试：**
///
/// ```bash
/// moon test -p typecheck -f typecheck_top_let_test.mbt
/// ```
/// ================================================================================

///|
test "Top Let Stmt Type Check" {
  let code =
    #|let x : Int = 42;
    #|let y = true;
  let ctx = Context::new()
  // Parse
  let tokens = @lexer.tokenize(code)
  // Type check for `let x : Int = 42;`
  let (top_let1, tok_view) = @parser.parse_top_let(tokens[:])
  let checked_top_let1 = ctx.check_top_let(top_let1)
  assert_true(checked_top_let1.ty is Int)
  let ty1 = ctx.lookup_type("x")
  assert_true(ty1 is Some(t) && t.kind is Int && t.mutable == false)

  // Type check for `let y = true;`
  let (top_let2, _) = @parser.parse_top_let(tok_view)
  let checked_top_let2 = ctx.check_top_let(top_let2)
  assert_true(checked_top_let2.ty is Bool)
  let ty2 = ctx.lookup_type("y")
  assert_true(ty2 is Some(t) && t.kind is Bool && t.mutable == false)
}
