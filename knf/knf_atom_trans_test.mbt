/// ================================================================================
/// # 🎯 完整原子表达式的 KNF 变换：处理复杂情况
///
/// 在完成了简单原子表达式的转换之后，我们现在要处理**完整的原子表达式 (Atom Expression)** 转换。
/// 这个测试将涵盖原子表达式的所有复杂情况，包括括号表达式、数组、元组、结构体构造等。
///
/// ## 🌟 原子表达式的完整类型
///
/// **原子表达式**是表达式的基础构建块，它们包括：
///
/// - **字面量**：`42`、`3.14`、`true`、`"hello"`、`()`
/// - **标识符**：`x`、`y`、`z`（变量名）
/// - **括号表达式**：`(a + b)`（包含复杂表达式）
/// - **数组字面量**：`[1, 2, 3]`、`[x, y, z]`
/// - **元组字面量**：`(x, y, z)`、`(a, b)`
/// - **数组构造**：`Array::make(5, 0)`
/// - **结构体构造**：`Point::{ x: 10, y: 20 }`
///
/// 在 KNF 变换中，我们的目标是将这些原子表达式转换为规范化的形式。
///
/// ## 🔍 复杂原子表达式的处理策略
///
/// 对于包含子表达式的原子表达式，我们需要采用**递归处理**的策略：
///
/// ### 1. 括号表达式 (Paren)
/// ```
/// Paren(inner_expr) => self.expr_to_knf(inner_expr)
/// ```
/// 直接递归调用 `expr_to_knf` 处理内部表达式。
///
/// ### 2. 数组字面量 (Array)
///
/// **关键步骤**：
/// 1. 遍历数组中的每个表达式
/// 2. 递归调用 `expr_to_knf` 处理每个表达式
/// 3. 合并所有语句
/// 4. 为每个表达式创建临时变量（如果需要）
/// 5. 返回 `ArrayLiteral` 结果
///
/// ### 3. 元组字面量 (Tuple)
///
/// 处理方式与数组字面量类似。
///
/// ### 4. 数组构造 (ArrayMake)
///
/// **关键步骤**：
/// 1. 分别处理大小表达式和初始化表达式
/// 2. 合并所有语句
/// 3. 为每个表达式创建临时变量
/// 4. 返回 `ArrayMake` 结果
///
/// ### 5. 结构体构造 (StructConstruct)
///
/// **关键步骤**：
/// 1. 遍历结构体的每个字段
/// 2. 递归处理每个字段的表达式
/// 3. 合并所有语句
/// 4. 为每个字段表达式创建临时变量
/// 5. 返回 `CreateStruct` 结果
///
/// ## 🎯 你的任务：完善 `atom_expr_to_knf` 函数
///
/// 在这个测试中，你需要完善 `Context::atom_expr_to_knf` 函数，
/// 处理所有类型的原子表达式。
///
/// ### 💡 实现思路
///
/// 对于包含子表达式的原子表达式，核心策略是：
/// 1. **递归调用** `expr_to_knf` 处理子表达式
/// 2. **合并语句** 将所有子表达式的语句合并
/// 3. **创建临时变量** 为复杂子表达式创建临时变量
/// 4. **构造结果** 使用临时变量构造最终的 KNF 表达式
///
/// ## 🚀 测试用例解析
///
/// 这个测试文件包含了多种复杂原子表达式的转换：
///
/// 1. **括号表达式**：`(a + b)` → `Binary(Add, a, b)`（无额外语句）
/// 2. **数组字面量**：`[1, 2, 3]` → `Let(tmp1, Int, Int(1)); Let(tmp2, Int, Int(2)); Let(tmp3, Int, Int(3)); ArrayLiteral([tmp1, tmp2, tmp3])`
/// 3. **元组字面量**：`(x, y, z)` → `TupleLiteral([x, y, z])`（无额外语句）
/// 4. **数组构造**：`Array::make(5, 0)` → `Let(tmp1, Int, Int(5)); Let(tmp2, Int, Int(0)); ArrayMake(tmp1, tmp2)`
/// 5. **结构体构造**：`Point::{ x: 10, y: 20 }` → `Let(tmp1, Int, Int(10)); Let(tmp2, Int, Int(20)); CreateStruct("Point", [("x", tmp1), ("y", tmp2)])`
///
/// ## 💡 实现提示
///
/// 1. **递归处理**：对于包含子表达式的原子表达式，使用 `expr_to_knf` 递归处理
/// 2. **语句合并**：使用 `append` 合并所有子表达式的语句
/// 3. **临时变量**：使用 `expr_to_knf_name` 为复杂表达式创建临时变量
/// 4. **类型转换**：使用 `typekind_to_knf` 转换类型信息
/// 5. **模式匹配**：使用 `match` 语句处理不同的原子表达式类型
///
/// ## 🔮 KNF 变换的完整性
///
/// 通过处理所有类型的原子表达式，我们实现了：
///
/// - **完整性**：覆盖了所有可能的原子表达式类型
/// - **一致性**：所有复杂情况都采用相同的递归处理策略
/// - **规范化**：将复杂的嵌套结构转换为简单的原子操作
/// - **可扩展性**：为后续的优化和代码生成提供了标准化的形式
///
/// ## 🎯 开始实现吧！
///
/// 这是原子表达式转换的完整版本！通过递归处理所有复杂情况，
/// 我们将原子表达式转换为规范化的 KNF 形式。
///
/// **准备好处理所有类型的原子表达式了吗？让我们开始实现！**
/// ================================================================================

///|
test "Atom Expr Knf Transformation Test" {
  // set a, b, x, y, z type in typecheck and knf context
  let typecheck_ctx = @typecheck.Context::new()
  typecheck_ctx.type_env.set("a", { kind: Int, mutable: false })
  typecheck_ctx.type_env.set("b", { kind: Int, mutable: false })
  typecheck_ctx.type_env.set("x", { kind: Double, mutable: false })
  typecheck_ctx.type_env.set("y", { kind: String, mutable: false })
  typecheck_ctx.type_env.set("z", { kind: Bool, mutable: false })
  let point_struct_def : @typecheck.StructDef = {
    name: "Point",
    fields: [
      { name: "x", ty: { kind: Int, mutable: false } },
      { name: "y", ty: { kind: Int, mutable: false } },
    ],
  }
  typecheck_ctx.struct_defs.set("Point", point_struct_def)
  let knf_ctx = Context::new()
  knf_ctx.globals.set("x", Double)
  let _ = knf_ctx.add_new_name("y", String)
  knf_ctx.enter_scope()
  let _ = knf_ctx.add_new_name("z", Bool)
  let _ = knf_ctx.add_new_name("a", Int)
  let _ = knf_ctx.add_new_name("b", Int)

  // Code parse, typecheck, knf transform
  let code =
    #|(a + b)
    #|[1, 2, 3]
    #|(x, y, z)
    #|Array::make(5, 0)
    #|Point::{ x: 10, y: 20 }
  let tokens = @lexer.tokenize(code)
  // Parse and transform `(a + b)`.
  let (e, tok_view) = @parser.parse_atom_expr(tokens)
  let e = typecheck_ctx.check_atom_expr(e)
  let (stmts, knf_expr) = knf_ctx.atom_expr_to_knf(e)
  assert_true(
    stmts is [] &&
    knf_expr is Binary(Add, l, r) &&
    l is { id: "a", .. } &&
    r is { id: "b", .. },
  )
  // Parse and transform `[1, 2, 3]`.
  let (e, tok_view) = @parser.parse_atom_expr(tok_view)
  let e = typecheck_ctx.check_atom_expr(e)
  let (stmts, knf_expr) = knf_ctx.atom_expr_to_knf(e)
  assert_true(
    stmts is [s1, s2, s3] &&
    s1 is Let(n1, Int, Int(1)) &&
    s2 is Let(n2, Int, Int(2)) &&
    s3 is Let(n3, Int, Int(3)) &&
    knf_expr is ArrayLiteral(_, [a1, a2, a3]) &&
    n1 == a1 &&
    n2 == a2 &&
    n3 == a3,
  )
  // Parse and transform `(x, y, z)`.
  let (e, tok_view) = @parser.parse_atom_expr(tok_view)
  let e = typecheck_ctx.check_atom_expr(e)
  let (stmts, knf_expr) = knf_ctx.atom_expr_to_knf(e)
  assert_true(
    stmts is [] &&
    knf_expr is TupleLiteral([t1, t2, t3]) &&
    t1 is { id: "x", .. } &&
    t2 is { id: "y", .. } &&
    t3 is { id: "z", .. },
  )
  // Parse and transform `Array::make(5, 0)`.
  let (e, tok_view) = @parser.parse_atom_expr(tok_view)
  let e = typecheck_ctx.check_atom_expr(e)
  let (stmts, knf_expr) = knf_ctx.atom_expr_to_knf(e)
  assert_true(
    stmts is [s1, s2] &&
    s1 is Let(n1, Int, Int(5)) &&
    s2 is Let(n2, Int, Int(0)) &&
    knf_expr is ArrayMake(size_name, init_name) &&
    size_name == n1 &&
    init_name == n2,
  )
  // Parse and transform `Point::{ x: 10, y: 20 }`.
  let (e, _) = @parser.parse_atom_expr(tok_view)
  let e = typecheck_ctx.check_atom_expr(e)
  let (stmts, knf_expr) = knf_ctx.atom_expr_to_knf(e)
  assert_true(
    stmts is [s1, s2] &&
    s1 is Let(n1, Int, Int(10)) &&
    s2 is Let(n2, Int, Int(20)) &&
    knf_expr is CreateStruct("Point", [("x", f1), ("y", f2)]) &&
    n1 == f1 &&
    n2 == f2,
  )
}

///|
test "Nest Tuple Expr Knf Transformation Test " {
  let typecheck_ctx = @typecheck.Context::new()
  let knf_ctx = Context::new()
  let code =
    #|((5,3), 6)
  let tokens = @lexer.tokenize(code)
  let (e, _) = @parser.parse_atom_expr(tokens)
  let e = typecheck_ctx.check_atom_expr(e)
  let (stmts, knf_expr) = knf_ctx.atom_expr_to_knf(e)
  assert_true(
    stmts is [s1, s2, s3, s4] &&
    s1 is Let(n1, Int, Int(5)) &&
    s2 is Let(n2, Int, Int(3)) &&
    s3 is Let(a1, _, TupleLiteral([b1, b2])) &&
    b1 == n1 &&
    b2 == n2 &&
    s4 is Let(a2, Int, Int(6)) &&
    knf_expr is TupleLiteral([a1_name, a2_name]) &&
    a1_name == a1 &&
    a2_name == a2,
  )
}
