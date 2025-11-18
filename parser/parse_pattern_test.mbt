/// ================================================================================
/// # 解构的力量：解析模式
///
/// 我们已经可以解析类型和复杂的表达式了。现在，我们来处理一个与它们紧密相关，
/// 但又有所不同的概念：**模式（Pattern）**。
///
/// ## 什么是模式？
///
/// 模式是一种用于“解构”和“绑定”值的语法。你其实已经见过它最简单的形式了。
/// 在 `let x = ...` 中，`x` 就是一个最简单的标识符模式（Identifier Pattern），它将 `=` 右侧的值绑定到变量 `x` 上。
///
/// 在更完备的语言中（包括 MoonBit，但 MiniMoonBit 未实现），模式会大放异彩的地方是 `match` 表达式：
///
/// ```moonbit
/// match my_tuple {
///   (x, 0) => // 当元组第二个元素为 0 时，将第一个元素绑定到 x
///   (_, y) => // 忽略第一个元素，将第二个元素绑定到 y
/// }
/// ```
///
/// 在 MiniMoonBit 中，我们主要在 `let` 语句中使用模式，例如 `let (a, b) = (1, 2)` 来同时绑定多个变量。
///
/// ## 🎯 你的任务：实现 `parse_pattern`
///
/// 你的任务是在 `parser/pattern.mbt` 中实现 `parse_pattern` 函数。
///
/// MiniMoonBit 支持的模式非常简单：
/// 1.  **通配符：** `_`
/// 2.  **标识符：** `x`
/// 3.  **元组：** `(p1, p2, ...)`，其中 `p1`, `p2` 等本身也是模式。
///
/// 相信聪明的你已经发现，解析模式的逻辑与解析元组类型、元组表达式的逻辑非常相似，
/// 只是构成它的基本元素更少（只有 `_`, `ident` 和 `(...)`）。
///
/// 鉴于你已经是我们解析器开发的“老兵”了，这里的教程就不再赘述。放手去实现吧！
///
/// 加油！🚀
///
/// **阶段性测试：**
///
/// ```bash
/// moon test -p parser -f parse_pattern_test.mbt
/// ```
/// ================================================================================

///|
test "Pattern Parsing Test" {
  let code =
    #|_ 
    #|a
    #|(a, b, _)
    #|(a, (b, c), _)
    #|((a, b), (c, d))
  let tokens = @lexer.tokenize(code)
  let (p, tok_view) = parse_pattern(tokens[:])
  assert_true(p.kind is Wildcard)
  let (p, tok_view) = parse_pattern(tok_view)
  assert_true(p.kind is Ident("a"))
  let (p, tok_view) = parse_pattern(tok_view)
  assert_true(
    p.kind is Tuple(ps) &&
    ps is [p1, p2, p3] &&
    p1.kind is Ident("a") &&
    p2.kind is Ident("b") &&
    p3.kind is Wildcard,
  )
  let (p, tok_view) = parse_pattern(tok_view)
  assert_true(
    p.kind is Tuple(ps) &&
    ps is [p1, p2, p3] &&
    p1.kind is Ident("a") &&
    p2.kind is Tuple(ps2) &&
    ps2 is [p21, p22] &&
    p21.kind is Ident("b") &&
    p22.kind is Ident("c") &&
    p3.kind is Wildcard,
  )
  let (p, _) = parse_pattern(tok_view)
  assert_true(
    p.kind is Tuple(ps) &&
    ps is [p1, p2] &&
    p1.kind is Tuple(ps1) &&
    ps1 is [p11, p12] &&
    p11.kind is Ident("a") &&
    p12.kind is Ident("b") &&
    p2.kind is Tuple(ps2) &&
    ps2 is [p21, p22] &&
    p21.kind is Ident("c") &&
    p22.kind is Ident("d"),
  )
}