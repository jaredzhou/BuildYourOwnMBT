/// ================================================================================
/// # 语句的基石：解析 let 语句
///
/// 我们已经掌握了 MiniMoonBit 中所有表达式、类型和模式的解析方法。
/// 现在，是时候将它们组合起来，开始解析**语句（Statements）**了！
///
/// `let` 语句是 MiniMoonBit 中最核心的语句，用于将一个表达式的值绑定到一个模式上。
///
/// ## `let` 语句的 EBNF 范式
///
/// `let` 语句的结构可以用 EBNF（扩展巴科斯-瑙尔范式）清晰地描述：
///
/// ```
/// let_stmt ::= "let" pattern (":" type)? "=" expr ";"
/// ```
///
/// 这段范式告诉我们：
/// 1.  一个 `let` 语句以 `let` 关键字开头。
/// 2.  后面跟着一个我们已经会解析的 `pattern`。
/// 3.  可选地（`?` 表示 0 次或 1 次），可以有一个冒号 `:` 和一个 `type`。
/// 4.  接着是一个必须有的等号 `=` 和一个 `expr`。
/// 5.  最后必须以分号 `;` 结尾。
///
/// ## 🎯 你的任务：实现 `parse_let_stmt`
///
/// 你的任务是在 `parser/let_stmt.mbt` 中实现 `parse_let_stmt` 函数。
///
/// 相信对于已经身经百战的你来说，这个任务已经没有什么难度了。
/// 你只需要严格按照 EBNF 范式描述的顺序，依次调用我们已经写好的
/// `parse_pattern`, `parse_type`, 和 `parse_expr` 函数，并正确处理分隔符（`:`、`=`、`;`）即可。
///
/// 加油，这是我们通向完整程序解析的倒数第二步！🎉
///
/// **阶段性测试：**
///
/// ```bash
/// moon test -p parser -f parse_let_stmt_test.mbt
/// ```
/// ================================================================================

///|
test "Let Stmt Parsing Test" {
  let code =
    #|let x : Int = 42;
    #|let (a, b) = (1, 2);
    #|let _ = println();
    #|let (_, (p, q)) = (r, s);
  let tokens = @lexer.tokenize(code)
  let (s, tok_view) = parse_let_stmt(tokens)
  assert_true(
    s.pattern.kind is Ident("x") &&
    s.ty is Some(ty) &&
    ty.kind is Int &&
    s.expr.kind is ApplyExpr(a) &&
    a.kind is AtomExpr(atom) &&
    atom.kind is Int(42),
  )
  let (s, tok_view) = parse_let_stmt(tok_view)
  assert_true(
    s.pattern.kind is Tuple(ps) &&
    ps is [p1, p2] &&
    p1.kind is Ident("a") &&
    p2.kind is Ident("b") &&
    s.ty is None &&
    s.expr.kind is ApplyExpr(a) &&
    a.kind is AtomExpr(atom) &&
    atom.kind is Tuple(es) &&
    es is [e1, e2] &&
    e1.kind is ApplyExpr(a1) &&
    a1.kind is AtomExpr(atom1) &&
    atom1.kind is Int(1) &&
    e2.kind is ApplyExpr(a2) &&
    a2.kind is AtomExpr(atom2) &&
    atom2.kind is Int(2),
  )
  let (s, tok_view) = parse_let_stmt(tok_view)
  assert_true(
    s.pattern.kind is Wildcard &&
    s.ty is None &&
    s.expr.kind is ApplyExpr(a) &&
    a.kind is Call(callee, []) &&
    callee.kind is AtomExpr(atom) &&
    atom.kind is Ident("println"),
  )
  let (s, _) = parse_let_stmt(tok_view)
  assert_true(
    s.pattern.kind is Tuple(ps) &&
    ps is [p1, p2] &&
    p1.kind is Wildcard &&
    p2.kind is Tuple(ps2) &&
    ps2 is [p21, p22] &&
    p21.kind is Ident("p") &&
    p22.kind is Ident("q") &&
    s.ty is None &&
    s.expr.kind is ApplyExpr(a) &&
    a.kind is AtomExpr(atom) &&
    atom.kind is Tuple(es) &&
    es is [e1, e2] &&
    e1.kind is ApplyExpr(a1) &&
    a1.kind is AtomExpr(atom1) &&
    atom1.kind is Ident("r") &&
    e2.kind is ApplyExpr(a2) &&
    a2.kind is AtomExpr(atom2) &&
    atom2.kind is Ident("s"),
  )
}