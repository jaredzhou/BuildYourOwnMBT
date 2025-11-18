/// ================================================================================
/// # 🎯 语句的 KNF 变换：统一的分发中心
///
/// 在完成了各种具体语句的转换之后，我们现在要实现**语句的统一分发中心**。
/// 这是 KNF 变换中的一个重要里程碑，因为它将所有的语句类型统一到一个入口点。
///
/// ## 🌟 什么是语句的统一分发？
///
/// **语句的统一分发**是将不同类型的语句路由到相应的处理函数：
///
/// ```
/// let x = 10;           // LetStmt -> let_stmt_to_knf
/// let mut y = 20;       // LetMutStmt -> let_mut_stmt_to_knf
/// x = 30;               // AssignStmt -> assign_stmt_to_knf
/// print_int(x);         // ExprStmt -> expr_to_knf + ExprStmt
/// return x;             // ReturnStmt(Some) -> expr_to_knf + Return
/// return;               // ReturnStmt(None) -> ReturnUnit
/// ```
///
/// **统一分发的特点**：
/// - **单一入口**：所有语句都通过 `stmt_to_knf` 处理
/// - **类型分发**：根据语句类型路由到相应的处理函数
/// - **一致性**：确保所有语句都采用相同的处理模式
/// - **可扩展性**：便于添加新的语句类型
///
/// ## 🔍 语句类型的处理策略
///
/// 对于不同的语句类型，需要采用不同的处理策略：
///
/// ### 1. LetStmt 和 LetMutStmt
/// - **直接委托**：直接调用相应的处理函数
/// - **模式匹配**：处理复杂的模式匹配
/// - **变量绑定**：创建变量绑定
///
/// ### 2. AssignStmt
/// - **左值处理**：处理复杂的左值结构
/// - **复合操作**：处理复合赋值操作
/// - **副作用**：处理状态修改
///
/// ### 3. ExprStmt
/// - **表达式处理**：使用 `expr_to_knf` 处理表达式
/// - **副作用处理**：处理表达式的副作用
/// - **ExprStmt 包装**：将结果包装为 `ExprStmt`
///
/// ### 4. ReturnStmt
/// - **有值返回**：`ReturnStmt(Some(expr))` -> `Return(expr)`
/// - **无值返回**：`ReturnStmt(None)` -> `ReturnUnit`
/// - **表达式处理**：对返回值进行 KNF 转换
///
/// ## 🎯 你的任务：实现 `stmt_to_knf` 函数
///
/// 在这个测试中，你需要实现 `Context::stmt_to_knf` 函数。
///
/// ### 💡 实现思路
///
/// 语句的统一分发采用**模式匹配**的策略：
///
/// 1. **模式匹配**：根据 `stmt.kind` 的类型进行匹配
/// 2. **直接委托**：对于已实现的语句类型，直接调用相应的处理函数
/// 3. **表达式处理**：对于 `ExprStmt` 和 `ReturnStmt`，需要处理表达式
/// 4. **特殊处理**：对于 `ReturnStmt(None)`，直接返回 `ReturnUnit`
///
/// ### 🔧 关键实现细节
///
/// #### ExprStmt 的处理
/// ```
/// ExprStmt(expr) => {
///   let (stmts, knf_expr) = self.expr_to_knf(expr)
///   stmts.append([KnfStmt::ExprStmt(knf_expr)])
///   stmts
/// }
/// ```
///
/// **关键点**：
/// - 使用 `expr_to_knf` 处理表达式
/// - 将结果包装为 `ExprStmt`
/// - 合并表达式可能产生的语句
///
/// #### ReturnStmt 的处理
/// ```
/// ReturnStmt(Some(expr)) => {
///   let (stmts, knf_expr) = self.expr_to_knf(expr)
///   stmts.append([KnfStmt::Return(knf_expr)])
///   stmts
/// }
/// ReturnStmt(None) => [KnfStmt::ReturnUnit]
/// ```
///
/// **关键点**：
/// - 有值返回：处理表达式并包装为 `Return`
/// - 无值返回：直接返回 `ReturnUnit`
/// - 注意 `ReturnUnit` 是单独的变体，不是 `Return(Unit)`
///
/// ## 🚀 测试用例解析
///
/// 这个测试文件包含了多种语句的综合转换：
///
/// ### 测试用例 1：`let mut p = Point::{ x: 0, y: 0 };`
/// **转换结果**：结构体构造的 Let Mut 语句
/// **特点**：复杂的初始化表达式
///
/// ### 测试用例 2：`let mut a = 100;`
/// **转换结果**：`LetMut(a, Int, Int(100))`
/// **特点**：简单的 Let Mut 语句
///
/// ### 测试用例 3：`let (b, c) = (200, 300);`
/// **转换结果**：元组解构的 Let 语句
/// **特点**：模式匹配和优化
///
/// ### 测试用例 4：`let arr = [a, b, c];`
/// **转换结果**：数组字面量的 Let 语句
/// **特点**：复杂表达式的处理
///
/// ### 测试用例 5：`a *= 50;`
/// **转换结果**：复合赋值语句
/// **特点**：复合操作的处理
///
/// ### 测试用例 6：`p.x += b + c;`
/// **转换结果**：复杂左值的复合赋值
/// **特点**：嵌套左值和复合操作
///
/// ### 测试用例 7：`arr[1] = a - 25;`
/// **转换结果**：数组赋值的 Assign 语句
/// **特点**：数组访问和复杂表达式
///
/// ### 测试用例 8：`return p;`
/// **转换结果**：`Return(Ident(p))`
/// **特点**：有值返回语句
///
/// ## 💡 实现提示
///
/// 1. **模式匹配**：使用 `match` 语句处理不同的语句类型
/// 2. **直接委托**：对于已实现的语句类型，直接调用相应的处理函数
/// 3. **表达式处理**：对于 `ExprStmt` 和 `ReturnStmt`，使用 `expr_to_knf`
/// 4. **语句合并**：使用 `append` 合并表达式可能产生的语句
/// 5. **特殊处理**：注意 `ReturnUnit` 是单独的变体
///
/// ## 🔮 设计思想
///
/// 统一分发的设计体现了以下思想：
///
/// - **单一职责**：每个处理函数专注于一种语句类型
/// - **一致性**：所有语句都采用相同的处理模式
/// - **可维护性**：便于添加新的语句类型
/// - **可测试性**：每种语句类型都可以独立测试
///
/// ## 🎯 开始实现吧！
///
/// 这是语句处理的统一入口！通过实现 `stmt_to_knf` 函数，
/// 我们将完成语句处理的最后一块拼图，为后续的程序处理奠定基础。
///
/// **准备好完成语句处理的统一分发了吗？让我们开始实现！**
/// ================================================================================

///|
test "Stmt Knf Transformation Test" {
  // Prelude Parts
  let typecheck_ctx = @typecheck.Context::new()
  let knf_ctx = @knf.Context::new()

  // Setup struct definition for testing
  let point_struct_def : @typecheck.StructDef = {
    name: "Point",
    fields: [
      { name: "x", ty: { kind: Int, mutable: true } },
      { name: "y", ty: { kind: Int, mutable: true } },
    ],
  }
  typecheck_ctx.struct_defs.set("Point", point_struct_def)

  // Set function context for return statement
  typecheck_ctx.current_func_ret_ty = Some(Struct("Point"))
  let code =
    #|let mut p = Point::{ x: 0, y: 0 };
    #|let mut a = 100;
    #|let (b, c) = (200, 300);
    #|let arr = [a, b, c];
    #|a *= 50;
    #|p.x += b + c;
    #|arr[1] = a - 25;
    #|return p;

  // Code parse, typecheck, knf transform
  let tokens = @lexer.tokenize(code)

  // Test 1: Parse and transform `let mut p = Point::{ mut x: 0, y: 0 };`
  let (stmt, tok_view) = @parser.parse_stmt(tokens)
  let stmt = typecheck_ctx.check_stmt(stmt)
  let knf_stmts = knf_ctx.stmt_to_knf(stmt)
  assert_true(
    knf_stmts is [s1, s2, s3] &&
    s1 is Let(_, Int, Int(0)) &&
    s2 is Let(_, Int, Int(0)) &&
    s3 is LetMut(name, Struct("Point"), CreateStruct("Point", fields)) &&
    name is { id: "p", .. } &&
    fields is [field1, field2] &&
    field1 is ("x", _) &&
    field2 is ("y", _),
  )

  // Test 2: Parse and transform `let mut a = 100;`
  let (stmt, tok_view) = @parser.parse_stmt(tok_view)
  let stmt = typecheck_ctx.check_stmt(stmt)
  let knf_stmts = knf_ctx.stmt_to_knf(stmt)
  assert_true(
    knf_stmts is [s] &&
    s is LetMut(name, Int, Int(100)) &&
    name is { id: "a", .. },
  )

  // Test 3: Parse and transform `let (b, c) = (200, 300);`
  let (stmt, tok_view) = @parser.parse_stmt(tok_view)
  let stmt = typecheck_ctx.check_stmt(stmt)
  let knf_stmts = knf_ctx.stmt_to_knf(stmt)
  assert_true(
    knf_stmts is [s1, s2, s3, s4] &&
    s1 is Let(n1, Int, Int(200)) &&
    s2 is Let(n2, Int, Int(300)) &&
    s3 is Let(b, _, Ident(n1_)) &&
    s4 is Let(c, _, Ident(n2_)) &&
    n1 == n1_ &&
    n2 == n2_ &&
    b is { id: "b", .. } &&
    c is { id: "c", .. },
  )

  // Test 4: Parse and transform `let arr = [a, b, c];`
  let (stmt, tok_view) = @parser.parse_stmt(tok_view)
  let stmt = typecheck_ctx.check_stmt(stmt)
  let knf_stmts = knf_ctx.stmt_to_knf(stmt)
  assert_true(
    knf_stmts is [s] &&
    s is Let(name, Array(Int), ArrayLiteral(_, elements)) &&
    name is { id: "arr", .. } &&
    elements is [elem1, elem2, elem3] &&
    elem1 is { id: "a", .. } &&
    elem2 is { id: "b", .. } &&
    elem3 is { id: "c", .. },
  )

  // Test 5: Parse and transform `a *= 50;`
  let (stmt, tok_view) = @parser.parse_stmt(tok_view)
  let stmt = typecheck_ctx.check_stmt(stmt)
  let knf_stmts = knf_ctx.stmt_to_knf(stmt)
  assert_true(
    knf_stmts is [s1, s2, s3] &&
    s1 is Let(_, Int, Int(50)) &&
    s2 is Let(_, Int, Binary(Mul, _, _)) &&
    s3 is Assign(name, Ident(_)) &&
    name is { id: "a", .. },
  )

  // Test 6: Parse and transform `p.x += b + c;`
  let (stmt, tok_view) = @parser.parse_stmt(tok_view)
  let stmt = typecheck_ctx.check_stmt(stmt)
  let knf_stmts = knf_ctx.stmt_to_knf(stmt)
  println("knf_stmts: \{knf_stmts.to_string()}")
  assert_true(
    knf_stmts is [s1, s2, s3, s4, s5] &&
    s1 is Let(n1, Int, FieldAccess(_, "x")) &&
    s2 is Let(n2, Int, Binary(Add, { id: "b", .. }, { id: "c", .. })) &&
    s3 is Let(n3, Int, Binary(Add, n1_, n2_)) &&
    s4 is Let(n4, Int, Ident(n3_)) &&
    s5 is StructFieldSet(_, "x", n4_) &&
    n1 == n1_ &&
    n2 == n2_ &&
    n3 == n3_ &&
    n4 == n4_,
  )

  // Test 7: Parse and transform `arr[1] = a - 25;`
  let (stmt, tok_view) = @parser.parse_stmt(tok_view)
  let stmt = typecheck_ctx.check_stmt(stmt)
  let knf_stmts = knf_ctx.stmt_to_knf(stmt)
  assert_true(
    knf_stmts is [s1, s2, s3] &&
    s1 is Let(_, Int, Int(1)) &&
    s2 is Let(_, Int, Int(25)) &&
    s3 is ArrayPut(_),
  )

  // Test 8: Parse and transform `return p;`
  let (stmt, _) = @parser.parse_stmt(tok_view)
  let stmt = typecheck_ctx.check_stmt(stmt)
  let knf_stmts = knf_ctx.stmt_to_knf(stmt)
  assert_true(
    knf_stmts is [s] &&
    s is Return(return_expr) &&
    return_expr is Ident({ id: "p", .. }),
  )
}
