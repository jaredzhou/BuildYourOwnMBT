/// ================================================================================
/// # 表达式解析的最终章：组合一切
///
/// 恭喜你！你已经分别构建了 `ApplyExpr`、`IfExpr`、`BlockExpr` 以及处理一元和二元操作的各种逻辑。
/// 现在，我们来到了表达式解析的最后一站：将所有这些部分在 `parse_expr` 函数中完美地组合起来。
///
/// ## 表达式的“分诊台”
///
/// `parse_expr` 函数就像一个急诊室的分诊台。当一串 Token 到来时，它需要快速判断这属于哪种“病例”，
/// 然后将其分发给对应的“专科医生”（也就是我们之前写的各个子解析器）。
///
/// ## 🎯 你的任务：完善 `parse_expr`
///
/// 你的任务是最后一次修改 `parser/expr.mbt` 中的 `parse_expr` 函数，使其能够处理所有类型的表达式。
///
/// **实现思路：**
///
/// 1.  **特殊情况优先：**
///     *   首先，检查开头的 Token 是否是 `if` 或 `{`。如果是，那么整个表达式就是一个 `IfExpr` 或 `BlockExpr`，
///       直接调用对应的 `parse_if_expr` 或 `parse_block_expr` 函数，然后返回结果。
///     *   接着，检查开头是否是一元操作符（`!` 或 `-`）。如果是，按照我们之前实现的一元操作逻辑进行解析。
///
/// 2.  **默认情况：**
///     *   如果以上情况都不匹配，那么它必然是一个以 `ApplyExpr` 开头的表达式，
///       后面可能跟着一系列的二元操作符（例如 `a + b * c`）。
///     *   在这种情况下，执行我们为二元操作符实现的、包含优先级处理的“调度场”算法。
///
/// 通过这种“特殊情况优先，一般情况置后”的策略，你就可以将所有独立的解析逻辑优雅地整合在一起。
///
/// **阶段性测试：**
///
/// 这个测试文件包含了一些将不同表达式（如 `if` 和二元操作）组合在一起的复杂场景，
/// 是对你最终 `parse_expr` 函数的终极考验。
///
/// ```bash
/// moon test -p parser -f parse_complex_expr_test.mbt
/// ```
///
/// **祝贺你！完成这一步，你的表达式解析器就真正大功告成了！** 🏆
/// ================================================================================

///|
test "Complex Expr Parsing Test" {
  let code =
    #|(if a > b { a; } else { b; }) + (if c < d { c; } else { d; }) ;
  let tokens = @lexer.tokenize(code)
  let (e, _) = parse_expr(tokens)
  assert_true(
    e.kind is BinaryExpr(Add, l, r) &&
    l.kind is ApplyExpr(a1) &&
    a1.kind is AtomExpr(a1) &&
    a1.kind is Paren(a1) &&
    a1.kind is IfExpr(_) &&
    r.kind is ApplyExpr(a2) &&
    a2.kind is AtomExpr(a2) &&
    a2.kind is Paren(a2) &&
    a2.kind is IfExpr(_),
  )
}