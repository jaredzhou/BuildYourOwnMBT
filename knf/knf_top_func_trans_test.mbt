/// ================================================================================
/// # 🔧 顶层函数的 KNF 转换
///
/// ## 🎯 什么是顶层函数？
///
/// 顶层函数是程序中最顶层的函数定义，它们定义全局可调用的函数。
/// 顶层函数的基本结构是：
/// fn function_name(param1: Type1, param2: Type2) -> ReturnType {
///   // 函数体
/// }
///
/// 顶层函数的特点：
/// - 定义了一个新的函数
/// - 包含参数列表、返回类型和函数体
/// - 函数体是一个 BlockExpr
/// - 需要在全局作用域中注册函数签名
/// - 函数参数在函数作用域中定义
///
/// ## 🔍 结构差异分析
///
/// 在语法树中，顶层函数的结构相对简单：
/// - `fname`: 函数名称（String）
/// - `param_list`: 参数列表（Array[Param]）
/// - `ret_ty`: 返回类型（TypeKind）
/// - `body`: 函数体（BlockExpr）
///
/// 在 KNF 中，顶层函数的结构更加统一：
/// - `KnfFunction`: 包含 name、ret_ty、params、body 的结构体
/// - `params`: 参数列表，每个参数包含（Name，Type）
/// - `body`: 函数体（KnfBlock）
///
/// ## 🛠️ 实现思路
///
/// 实现 `top_function_to_knf` 函数需要五个主要步骤：
///
/// ### 1. 进入函数作用域
/// - 使用 `enter_scope()` 创建新的作用域
/// - 为函数参数和局部变量提供独立的作用域
///
/// ### 2. 参数处理
/// - 遍历参数列表，为每个参数创建 Name
/// - 使用 `typekind_to_knf` 转换参数类型
/// - 将参数注册到当前作用域中
/// - 收集参数信息用于函数类型构造
///
/// ### 3. 返回类型转换
/// - 使用 `typekind_to_knf` 转换返回类型
/// - 构造函数类型 `Function(param_types, ret_ty)`
///
/// ### 4. 函数体转换
/// - 使用 `block_expr_to_knf` 转换函数体
/// - 函数体中的所有语句都在函数作用域中处理
///
/// ### 5. 退出作用域并注册
/// - 使用 `exit_scope()` 退出函数作用域
/// - 将函数注册到全局作用域中
/// - 返回 `KnfFunction` 结构
///
/// ## 🔧 关键实现细节
///
/// ### 作用域管理
/// 顶层函数的转换需要谨慎管理作用域：
/// - 在开始处理参数前进入作用域
/// - 在函数体转换完成后退出作用域
/// - 确保参数和局部变量在正确的作用域中
///
/// ### 参数处理
/// 为每个参数创建 Name 并注册到作用域：
/// fn add(x: Int, y: Int) -> Int { ... }
/// 转换为：
/// - 创建 Name { id: "x", slot: 0 } 和 Name { id: "y", slot: 0 }
/// - 注册到当前作用域
/// - 收集参数类型用于函数类型构造
///
/// ### 函数类型构造
/// 构造函数类型用于全局注册：
/// - 参数类型列表：[Int, Int]
/// - 返回类型：Int
/// - 函数类型：Function([Int, Int], Int)
///
/// ### 全局注册
/// 将函数注册到全局作用域：
/// - 使用函数名作为键
/// - 使用函数类型作为值
/// - 确保函数可以被其他代码调用
///
/// ## 📝 测试用例解析
///
/// ### 测试用例 1：简单函数
/// fn add(x: Int, y: Int) -> Int {
///   return x + y;
/// }
/// 转换过程：
/// 1. 进入作用域
/// 2. 处理参数：x, y
/// 3. 转换函数体：return x + y;
/// 4. 退出作用域
/// 5. 注册到全局作用域
///
/// ### 测试用例 2：Unit 返回类型
/// fn greet(name: String) -> Unit {
///   return ();
/// }
/// 转换过程：
/// 1. 进入作用域
/// 2. 处理参数：name
/// 3. 转换函数体：return ();
/// 4. 退出作用域
/// 5. 注册到全局作用域
///
/// ### 测试用例 3：递归函数
/// fn fib(n: Int) -> Int {
///   if n <= 1 {
///     return n;
///   } else {
///     return fib(n - 1) + fib(n - 2);
///   }
/// }
/// 转换过程：
/// 1. 进入作用域
/// 2. 处理参数：n
/// 3. 转换函数体：if 表达式和递归调用
/// 4. 退出作用域
/// 5. 注册到全局作用域
///
/// ### 测试用例 4：多语句函数
/// fn compute(a: Int, b: Int, c: Int) -> Int {
///   let sum = a + b;
///   let result = sum * c;
///   return result;
/// }
/// 转换过程：
/// 1. 进入作用域
/// 2. 处理参数：a, b, c
/// 3. 转换函数体：let 语句和 return 语句
/// 4. 退出作用域
/// 5. 注册到全局作用域
///
/// ## 💡 设计思想
///
/// ### 作用域隔离
/// 每个函数都有独立的作用域，参数和局部变量不会相互干扰。
///
/// ### 参数管理
/// 参数在函数作用域中定义，可以被函数体中的语句使用。
///
/// ### 全局注册
/// 函数定义后需要注册到全局作用域，供其他代码调用。
///
/// ### 类型安全
/// 确保函数参数和返回类型的类型安全。
///
/// ## 🚀 实现挑战
///
/// ### 作用域时机
/// 需要谨慎决策进入作用域和退出作用域的时机：
/// - 在参数处理前进入作用域
/// - 在函数体转换完成后退出作用域
/// - 确保全局注册在作用域外进行
///
/// ### 参数处理
/// 需要正确处理参数列表，为每个参数创建 Name 并注册到作用域。
///
/// ### 函数类型构造
/// 需要正确构造函数类型，包括参数类型列表和返回类型。
///
/// ### 全局注册
/// 需要将函数正确注册到全局作用域，确保函数可以被调用。
///
/// ## 🎯 实现目标
///
/// 完成 `function.mbt` 中的 `top_function_to_knf` 函数，实现顶层函数的 KNF 转换。
/// 函数应该：
/// 1. 正确管理函数作用域（enter_scope 和 exit_scope）
/// 2. 正确处理参数列表，为每个参数创建 Name
/// 3. 正确转换参数类型和返回类型
/// 4. 正确转换函数体为 KNF
/// 5. 将函数注册到全局作用域
/// 6. 返回统一的 KnfFunction 结构
///
/// 现在让我们开始实现顶层函数的转换吧！🚀
///
/// ================================================================================

///|
test "Top Function Knf Transformation Test" {
  // Prelude Parts
  let typecheck_ctx = @typecheck.Context::new()
  let knf_ctx = @knf.Context::new()

  // Setup builtin functions
  typecheck_ctx.func_types.set("print_int", Function([Int], Unit))
  typecheck_ctx.type_env.set("print_int", {
    kind: Function([Int], Unit),
    mutable: false,
  })
  knf_ctx.globals.set("print_int", Function([Int], Unit))
  let code =
    #|fn add(x: Int, y: Int) -> Int {
    #|  return x + y;
    #|}
    #|fn greet(name: String) -> Unit {
    #|  return ();
    #|}
    #|fn fib(n: Int) -> Int {
    #|  if n <= 1 {
    #|    return n;
    #|  } else {
    #|    return fib(n - 1) + fib(n - 2);
    #|  }
    #|}
    #|fn compute(a: Int, b: Int, c: Int) -> Int {
    #|  let sum = a + b;
    #|  let result = sum * c;
    #|  return result;
    #|}

  // Register function signatures first
  typecheck_ctx.func_types.set("add", Function([Int, Int], Int))
  typecheck_ctx.type_env.set("add", {
    kind: Function([Int, Int], Int),
    mutable: false,
  })
  typecheck_ctx.func_types.set("greet", Function([String], Unit))
  typecheck_ctx.type_env.set("greet", {
    kind: Function([String], Unit),
    mutable: false,
  })
  typecheck_ctx.func_types.set("fib", Function([Int], Int))
  typecheck_ctx.type_env.set("fib", {
    kind: Function([Int], Int),
    mutable: false,
  })
  typecheck_ctx.func_types.set("compute", Function([Int, Int, Int], Int))
  typecheck_ctx.type_env.set("compute", {
    kind: Function([Int, Int, Int], Int),
    mutable: false,
  })
  let tokens = @lexer.tokenize(code)

  // Test 1: Simple function with two parameters and return
  let (top_func1, tok_view) = @parser.parse_top_function(tokens)
  let checked_func1 = typecheck_ctx.check_top_function(top_func1)
  let knf_func1 = knf_ctx.top_function_to_knf(checked_func1)
  assert_true(knf_func1.name == "add")
  assert_true(knf_func1.ret_ty is Int)
  assert_true(knf_func1.params.length() is 2)
  assert_true(
    knf_func1.params[0] is (param_name1, param_type1) &&
    param_name1 is { id: "x", slot: 0 } &&
    param_type1 is Int,
  )
  assert_true(
    knf_func1.params[1] is (param_name2, param_type2) &&
    param_name2 is { id: "y", slot: 0 } &&
    param_type2 is Int,
  )
  // Body should have: return x + y;
  assert_true(knf_func1.body.stmts.length() is 1)
  assert_true(
    knf_func1.body.stmts is [s] &&
    s is Return(Binary(Add, x_name, y_name)) &&
    x_name is { id: "x", .. } &&
    y_name is { id: "y", .. },
  )

  // Test 2: Function with String parameter returning Unit
  let (top_func2, tok_view) = @parser.parse_top_function(tok_view)
  let checked_func2 = typecheck_ctx.check_top_function(top_func2)
  let knf_func2 = knf_ctx.top_function_to_knf(checked_func2)
  assert_true(knf_func2.name == "greet")
  assert_true(knf_func2.ret_ty is Unit)
  assert_true(knf_func2.params.length() is 1)
  assert_true(
    knf_func2.params is [(param_name3, param_type3)] &&
    param_name3 is { id: "name", slot: 0 } &&
    param_type3 is String,
  )
  // Body should have: return ();
  assert_true(knf_func2.body.stmts.length() is 1)
  assert_true(knf_func2.body.stmts[0] is Return(Unit))

  // Test 3: Recursive function with if expression
  let (top_func3, tok_view) = @parser.parse_top_function(tok_view)
  let checked_func3 = typecheck_ctx.check_top_function(top_func3)
  println("checked_func3: \{checked_func3.to_string()}")
  let knf_func3 = knf_ctx.top_function_to_knf(checked_func3)
  assert_true(knf_func3.name == "fib")
  assert_true(knf_func3.ret_ty is Int)
  assert_true(knf_func3.params.length() is 1)
  assert_true(
    knf_func3.params[0] is (param_name4, param_type4) &&
    param_name4 is { id: "n", slot: 0 } &&
    param_type4 is Int,
  )
  // Body should contain if expression and recursive calls
  // We don't need to verify the exact structure, just that it's transformed
  assert_true(knf_func3.body.stmts.length() > 0)

  // Test 4: Function with multiple statements in body
  let (top_func4, _) = @parser.parse_top_function(tok_view)
  let checked_func4 = typecheck_ctx.check_top_function(top_func4)
  let knf_func4 = knf_ctx.top_function_to_knf(checked_func4)
  assert_true(knf_func4.name == "compute")
  assert_true(knf_func4.ret_ty is Int)
  assert_true(knf_func4.params.length() is 3)
  // Body should have: let sum = a + b; let result = sum * c; return result;
  assert_true(knf_func4.body.stmts.length() is 3)
  assert_true(
    knf_func4.body.stmts[0] is Let(sum_name, Int, Binary(Add, a_name, b_name)) &&
    sum_name is { id: "sum", .. } &&
    a_name is { id: "a", .. } &&
    b_name is { id: "b", .. },
  )
  assert_true(
    knf_func4.body.stmts[1]
    is Let(result_name, Int, Binary(Mul, sum_name2, c_name)) &&
    result_name is { id: "result", .. } &&
    sum_name2 is { id: "sum", .. } &&
    c_name is { id: "c", .. },
  )
  assert_true(
    knf_func4.body.stmts[2] is Return(Ident(result_name2)) &&
    result_name2 is { id: "result", .. },
  )
}
