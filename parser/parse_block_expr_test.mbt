/// ================================================================================
/// # 代码块的力量：解析 BlockExpr
///
/// 我们已经可以解析独立的语句了。现在，我们要将它们组织到一个非常重要的结构中：
/// **代码块表达式（Block Expression）**。
///
/// 在 MiniMoonBit 中，代码块由 `{}` 包裹，它本身也是一个表达式，其值是块内最后一条表达式的值。
///
/// ## BlockExpr 的 EBNF 范式
///
/// ```
/// block_expr ::= "{" stmt* expr? "}"
/// ```
///
/// 这段范式告诉我们，一个代码块包含：
/// 1.  一个起始的 `{"{"`。
/// 2.  零条或多条（`*`）以分号结尾的语句（`stmt`）。
/// 3.  可选地（`?`），最后可以有一条不带分号的表达式（`expr`），它的值就是整个块的值。
/// 4.  一个终结的 `"}"`。
///
/// ## 🎯 你的任务：实现 `parse_block_expr`
///
/// 你的任务是在 `parser/block_expr.mbt` 中实现 `parse_block_expr` 函数。
///
/// **实现思路：**
///
/// 1.  匹配并跳过开头的 `{"{"`。
/// 2.  进入一个循环，反复调用 `parse_stmt` 来解析块内的每一条语句。
/// 3.  循环直到遇到 `"}"` 为止。
/// 4.  匹配并跳过结尾的 `"}"`。
///
/// ### 🤔 一个棘手的问题：如何处理最后一条“不带分号”的表达式？
///
/// EBNF 中的 `expr?` 是整个解析过程中的一个难点。
/// `let x = { let y = 1; y + 1 }` 是合法的，最后的 `y + 1` 没有分号。
///
/// 这意味着，当我们的 `parse_stmt` 在解析一个可能是 `expr_stmt` 的语句时，
/// 它不能再固执地要求结尾必须是 `;` 了。
///
/// **💡 提示：**
///
/// 解决这个问题的关键在于**修改 `parse_stmt` 函数**。
///
/// 当 `parse_stmt` 解析完一个 `expr_stmt` 后，它需要检查下一个 Token：
/// *   如果 Token 是 `;`，那么消耗它，语句结束。
/// *   如果 Token 是 `}`，那么说明这已经是块的结尾了，**不消耗它**，直接将 `expr_stmt` 返回。
/// *   如果是其他 Token，则应该报错。
///
/// 通过在 `parse_stmt` 中增加对 `}` 的“宽容”，`parse_block_expr` 的实现就可以保持非常简单。
///
/// **阶段性测试：**
///
/// ```bash
/// moon test -p parser -f parse_block_expr_test.mbt
/// ```
/// ================================================================================

///|
test "Block Expr Parsing" {
  let code =
    #|{
    #|  let x = 10;
    #|  let mut y = 20;
    #|  y = y + x;
    #|  let t = Array::make(5, 0);
    #|  t[0] = y;
    #|}
  let tokens = @lexer.tokenize(code)
  let (block, _) = parse_block_expr(tokens)
  assert_true(block.stmts.length() is 5)
  assert_true(block.stmts[0].kind is LetStmt(_))
  assert_true(block.stmts[1].kind is LetMutStmt(_))
  assert_true(block.stmts[2].kind is AssignStmt(_))
  assert_true(block.stmts[3].kind is LetStmt(_))
  assert_true(block.stmts[4].kind is AssignStmt(_))
}