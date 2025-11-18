/// ================================================================================
/// # 🎯 赋值语句的 KNF 变换：左值的复杂性
///
/// 在完成了 Let 语句的转换之后，我们现在要处理**赋值语句 (Assignment Statement)** 的转换。
/// 这是 KNF 变换中的一个重要挑战，因为它涉及到**左值 (Left Value)** 的复杂处理。
///
/// ## 🌟 什么是赋值语句？
///
/// **赋值语句**是修改变量值的语句，它们的形式是：
///
/// ```
/// x = 10;              // 简单赋值
/// y += 5;              // 复合赋值
/// mat[0][0] = 42;      // 复杂左值赋值
/// point.x = 100;       // 字段赋值
/// ```
///
/// **赋值语句的特点**：
/// - **左值**：左侧必须是可修改的位置（变量、数组元素、字段等）
/// - **右值**：右侧是表达式，计算结果赋值给左值
/// - **复合操作**：支持 `+=`、`-=`、`*=` 等复合赋值操作
/// - **副作用**：修改程序状态
///
/// ## 🔍 左值的复杂性挑战
///
/// 赋值语句的核心挑战在于**左值的复杂性**，特别是**嵌套左值**：
///
/// ### 问题：嵌套左值的处理
///
/// 对于 `mat[0][0] = 42` 这样的语句，左值 `mat[0][0]` 是嵌套的：
///
/// ```
/// mat[0][0] = 42
///     ↑     ↑
///   外层左值 内层左值
/// ```
///
/// **挑战**：
/// - 外层左值 `mat[0]` 需要被当作表达式处理
/// - 内层左值 `[0]` 需要访问外层左值的结果
/// - 需要正确处理中间结果的存储
///
/// ### 解决方案：左值到表达式的转换
///
/// 对于复杂的左值，需要采用**左值到表达式的转换**策略：
///
/// ```
/// mat[0][0] = 42
/// ```
///
/// **转换过程**：
/// 1. 处理外层左值 `mat[0]`，将其转换为表达式
/// 2. 为外层左值的结果创建临时变量
/// 3. 处理内层左值 `[0]`，使用临时变量作为数组
/// 4. 生成 `ArrayPut` 语句
///
/// ## 🎯 你的任务：实现 `assign_stmt_to_knf` 函数
///
/// 在这个测试中，你需要实现 `Context::assign_stmt_to_knf` 函数。
///
/// ### 💡 实现思路
///
/// 赋值语句的转换分为三个主要步骤：
///
/// 1. **处理左值**：使用 `left_value_to_knf` 处理左侧左值
/// 2. **处理右值**：使用 `expr_to_knf` 处理右侧表达式
/// 3. **生成赋值语句**：根据左值类型生成相应的 KNF 语句
///
/// ### 🔧 左值处理的核心策略
///
/// 对于不同的左值类型，需要采用不同的策略：
///
/// #### 1. 简单标识符左值
/// - 直接查找变量名
/// - 生成 `Assign` 语句
///
/// #### 2. 数组访问左值
/// - **递归处理**：对嵌套的数组访问递归处理
/// - **表达式转换**：将左值转换为表达式
/// - **临时变量**：为中间结果创建临时变量
/// - **ArrayPut 语句**：生成数组赋值语句
///
/// #### 3. 字段访问左值
/// - **递归处理**：对嵌套的字段访问递归处理
/// - **表达式转换**：将左值转换为表达式
/// - **临时变量**：为中间结果创建临时变量
/// - **StructFieldSet 语句**：生成字段赋值语句
///
/// ### 🔧 复合赋值操作的处理
///
/// 对于 `+=`、`-=` 等复合赋值操作：
///
/// 1. **读取左值**：将左值转换为表达式并读取其值
/// 2. **计算新值**：执行相应的二元运算
/// 3. **赋值**：将计算结果赋值给左值
///
/// ## 🚀 测试用例解析
///
/// 这个测试文件包含了多种赋值语句的转换：
///
/// ### 测试用例 1：`x = 10;`
/// **转换结果**：`Assign(x, Int(10))`
/// **特点**：简单的标识符赋值
///
/// ### 测试用例 2：`x += 5;`
/// **期望转换**：
/// ```
/// let tmp1 = 5;
/// let tmp2 = x + tmp1;
/// x = tmp2;
/// ```
/// **特点**：复合赋值操作
///
/// ### 测试用例 3：`mat[0][0] = 42;`
/// **期望转换**：
/// ```
/// let tmp1 = 0;
/// let tmp2 = mat[tmp1];
/// let tmp3 = 0;
/// ArrayPut(tmp2, tmp3, 42);
/// ```
/// **关键点**：嵌套左值的处理
///
/// ### 测试用例 4：`point.x = 100;`
/// **期望转换**：
/// ```
/// let tmp1 = 100;
/// StructFieldSet(point, "x", tmp1);
/// ```
/// **特点**：字段赋值
///
/// ## 💡 实现提示
///
/// 1. **左值处理**：使用 `left_value_to_knf` 处理复杂左值
/// 2. **表达式转换**：将左值转换为表达式进行处理
/// 3. **临时变量**：为中间结果创建临时变量
/// 4. **递归处理**：对嵌套左值使用递归策略
/// 5. **复合操作**：正确处理复合赋值操作
///
/// ## 🔮 优化思考
///
/// 在实现过程中，考虑以下优化问题：
///
/// ### 问题：如何减少临时变量？
/// 对于 `mat[0][0] = 42`，是否可以直接生成：
/// ```
/// ArrayPut(mat, 0, 42);
/// ```
///
/// **思考**：
/// - 这在简单情况下是可能的
/// - 但在复杂嵌套情况下可能难以实现
/// - 需要深入分析左值的结构
///
/// ### 更好的方式？
/// 考虑是否有更好的优化策略：
/// - 在哪个阶段进行优化更合适？
/// - 如何平衡实现的复杂度和优化效果？
/// - 如何确保优化的正确性？
///
/// ## 🎯 开始实现吧！
///
/// **准备好迎接左值处理的挑战了吗？让我们开始实现！**
/// ================================================================================

///|
test "Assign Stmt Knf Transformation Test" {
  // Prelude Parts
  // set x, y type in typecheck and knf context
  let typecheck_ctx = @typecheck.Context::new()
  let point_struct_def : @typecheck.StructDef = {
    name: "Point",
    fields: [{ name: "x", ty: { kind: Int, mutable: true } }],
  }
  typecheck_ctx.struct_defs.set("Point", point_struct_def)
  typecheck_ctx.type_env.set("x", { kind: Int, mutable: true })
  typecheck_ctx.type_env.set("y", { kind: Double, mutable: true })
  typecheck_ctx.type_env.set("mat", { kind: Array(Array(Int)), mutable: true })
  typecheck_ctx.type_env.set("point", { kind: Struct("Point"), mutable: false })
  let knf_ctx = Context::new()
  let _ = knf_ctx.add_new_name("x", Int)
  let _ = knf_ctx.add_new_name("y", Double)
  let _ = knf_ctx.add_new_name("arr", Array(Int))
  let _ = knf_ctx.add_new_name("point", Struct("Point"))
  let _ = knf_ctx.add_new_name("mat", Array(Array(Int)))

  // Test Parts
  let code =
    #|x = 10;
    #|y = 3.14;
    #|x += 5;
    #|y -= 1.0;
    #|mat[0][0] = 42;
    #|point.x = 100;
  // Code parse, typecheck, knf transform
  let tokens = @lexer.tokenize(code)

  // Parse and transform `x = 10;`
  let (stmt, tok_view) = @parser.parse_assign_stmt(tokens)
  let stmt = typecheck_ctx.check_assign_stmt(stmt)
  let knf_stmts = knf_ctx.assign_stmt_to_knf(stmt)
  assert_true(
    knf_stmts is [s] &&
    s is Assign(name, expr) &&
    name is { id: "x", .. } &&
    expr is Int(10),
  )

  // Parse and transform `y = 3.14;`
  let (stmt, tok_view) = @parser.parse_assign_stmt(tok_view)
  let stmt = typecheck_ctx.check_assign_stmt(stmt)
  let knf_stmts = knf_ctx.assign_stmt_to_knf(stmt)
  assert_true(
    knf_stmts is [s] &&
    s is Assign(name, expr) &&
    name is { id: "y", .. } &&
    expr is Double(3.14),
  )

  // Parse and transform `x += 5;`
  let (stmt, tok_view) = @parser.parse_assign_stmt(tok_view)
  let stmt = typecheck_ctx.check_assign_stmt(stmt)
  let knf_stmts = knf_ctx.assign_stmt_to_knf(stmt)
  println("knf_stmts: \{knf_stmts}")
  assert_true(
    knf_stmts is [s1, s2, s3] &&
    s1 is Let(_, Int, Int(5)) &&
    s2 is Let(_, Int, Binary(Add, _, _)) &&
    s3 is Assign(name, Ident(_)) &&
    name is { id: "x", .. },
  )

  // Parse and transform `y -= 1.0;`
  let (stmt, tok_view) = @parser.parse_assign_stmt(tok_view)
  let stmt = typecheck_ctx.check_assign_stmt(stmt)
  let knf_stmts = knf_ctx.assign_stmt_to_knf(stmt)
  assert_true(
    knf_stmts is [s1, s2, s3] &&
    s1 is Let(_, Double, Double(1.0)) &&
    s2 is Let(_, Double, Binary(Sub, _, _)) &&
    s3 is Assign(name, Ident(_)) &&
    name is { id: "y", .. },
  )
  // Parse and transform `max[0][0] = 42;`
  let (stmt, tok_view) = @parser.parse_assign_stmt(tok_view)
  let stmt = typecheck_ctx.check_assign_stmt(stmt)
  let knf_stmts = knf_ctx.assign_stmt_to_knf(stmt)
  assert_true(
    knf_stmts is [s1, s2, s3, s4] &&
    s1 is Let(n1, Int, Int(0)) &&
    s2 is Let(n2, Array(Int), ArrayAccess(_, mat_idx_name)) &&
    s3 is Let(n3, Int, Int(0)) &&
    s4 is ArrayPut(array_name, idx_name, Int(42)) &&
    n1 == mat_idx_name &&
    array_name == n2 &&
    idx_name == n3,
  )
  // Parse and transform `point.x = 100;`
  let (stmt, _) = @parser.parse_assign_stmt(tok_view)
  let stmt = typecheck_ctx.check_assign_stmt(stmt)
  let knf_stmts = knf_ctx.assign_stmt_to_knf(stmt)
  println("knf_stmts: \{knf_stmts}")
  assert_true(
    knf_stmts is [s1, s2] &&
    s1 is Let(n1, Int, Int(100)) &&
    s2 is StructFieldSet(_, "x", value_name) &&
    n1 == value_name,
  )
}
