/// ================================================================================
/// # 语句的“总指挥”：解析 Stmt
///
/// 我们已经集齐了 `let`、`let mut` 和 `assign` 等语句的解析器。
/// 现在，是时候创建一个“总指挥”——`parse_stmt` 函数，来统一调度它们了。
///
/// ## Stmt 的构成
///
/// 一个通用的语句（`Stmt`）可以是多种具体语句中的任何一种：
///
/// ```
/// stmt ::= let_stmt | let_mut_stmt | assign_stmt | expr_stmt
/// ```
///
/// `expr_stmt` 指的是一个表达式本身也可以作为一条语句，例如一个函数调用 `println("hello");`。
///
/// ## 🎯 你的任务：实现 `parse_stmt`
///
/// 你的任务是在 `parser/stmt.mbt` 中实现 `parse_stmt` 函数。
/// 这个函数需要根据开头的 Token 来判断应该调用哪个具体的语句解析器。
///
/// *   如果开头是 `let` 关键字，你需要进一步判断第二个 Token 是不是 `mut`，然后分别调用 `parse_let_stmt` 或 `parse_let_mut_stmt`。
///
/// ### 🤔 一个棘手的问题：`assign_stmt` vs `expr_stmt`
///
/// 最大的挑战在于区分 `assign_stmt` 和 `expr_stmt`。
///
/// *   `x = 1;` 是一个赋值语句。
/// *   `x(1);` 是一个表达式语句。
///
/// 它们都以一个标识符 `x` 开头！我们无法仅凭第一个 Token 就做出判断。
/// 这种“无法仅通过向前看一个 Token 来确定语法结构”的问题，在解析器中被称为 **LL(1) 冲突**。
///
/// **解决思路（预测与回溯）：**
///
/// 我们可以采用一种“试探-回溯”的策略：
///
/// 1.  **大胆预测：** 当语句以一个标识符开头时，我们**乐观地**假设它可能是一个赋值语句。因此，我们先尝试调用 `parse_left_value` 来解析一个左值。
///
/// 2.  **验证预测：** 解析完左值后，检查紧跟其后的 Token：
///     *   如果是一个**赋值操作符**（`=`、`+=` 等），那么我们的预测是正确的！这确实是一个 `assign_stmt`。此时，我们继续调用 `parse_assign_stmt` 来完成剩余部分的解析。
///     *   如果**不是**赋值操作符，那么我们的预测失败了。这意味着它不是一个赋值语句，而应该是一个 `expr_stmt`。
///
/// 3.  **回溯：** 预测失败后，我们需要“回溯”。这意味着我们要**丢弃**刚刚 `parse_left_value` 的解析结果，将 Token 视图**退回**到最初的位置，然后调用 `parse_expr` 将整条语句作为 `expr_stmt` 来重新解析。
///
/// 这种“预测-验证-回溯”的机制是手动编写递归下降解析器时处理语法歧义的常用技巧。
///
/// 加油，这是我们解析器部分的最后一个核心挑战！
///
/// **阶段性测试：**
///
/// ```bash
/// moon test -p parser -f parse_simple_stmt_test.mbt
/// ```
/// ================================================================================

///|
test "Stmt Parsing Test" {
  let code =
    #|let x = 5;
    #|let mut y = 10;
    #|y = y + x;
    #|y();
    #|println(123);
    #|print_int(foo(1, 2));
    #|foo.bar[3][4] = 42;
    #|return 0;
    #|return ;
  let tokens = @lexer.tokenize(code)
  let (s, tok_view) = parse_stmt(tokens[:])
  assert_true(s.kind is LetStmt(_))
  let (s, tok_view) = parse_stmt(tok_view)
  assert_true(s.kind is LetMutStmt(_))
  let (s, tok_view) = parse_stmt(tok_view)
  assert_true(s.kind is AssignStmt(_))
  let (s, tok_view) = parse_stmt(tok_view)
  assert_true(s.kind is ExprStmt(_))
  let (s, tok_view) = parse_stmt(tok_view)
  assert_true(s.kind is ExprStmt(_))
  let (s, tok_view) = parse_stmt(tok_view)
  assert_true(s.kind is ExprStmt(_))
  let (s, tok_view) = parse_stmt(tok_view)
  assert_true(s.kind is AssignStmt(_))
  let (s, tok_view) = parse_stmt(tok_view)
  assert_true(s.kind is ReturnStmt(_))
  let (s, _) = parse_stmt(tok_view)
  assert_true(s.kind is ReturnStmt(_))
}