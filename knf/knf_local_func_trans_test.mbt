/// ================================================================================
/// # 🔒 局部函数的 KNF 转换（闭包）
///
/// 接下来，我们将学习如何将局部函数转换为 KNF 形式。
/// 这是一个**难点**，需要深入理解闭包和变量捕获的概念。
///
/// ## 🎯 什么是局部函数？
///
/// 局部函数是在其他函数内部定义的函数，它们可以访问外部函数的变量。
/// 局部函数的基本结构是：
/// fn outer_function() -> Unit {
///   let x = 1;
///   fn inner_function() -> Unit {
///     // 可以访问 x
///   }
/// }
///
/// 局部函数的特点：
/// - 定义在其他函数内部
/// - 可以访问外部函数的变量（闭包）
/// - 需要记录捕获的变量
/// - 形成嵌套的作用域结构
///
/// ## 🔍 结构差异分析
///
/// 在语法树中，局部函数的结构相对简单：
/// - `fname`: 函数名称（String）
/// - `param_list`: 参数列表（Array[(String, Type)]）
/// - `ret_ty`: 返回类型（Type）
/// - `body`: 函数体（BlockExpr）
///
/// 在 KNF 中，局部函数被转换为闭包：
/// - `KnfClosure`: 包含 name、params、ret_ty、body、captured_vars 的结构体
/// - `captured_vars`: 捕获的变量映射（Map[Name, Type]）
/// - 需要记录哪些变量被捕获
///
/// ## 🛠️ 实现思路
///
/// 实现 `local_function_to_knf` 函数需要四个主要步骤：
///
/// ### 1. 函数类型构造
/// - 遍历参数列表，转换参数类型
/// - 转换返回类型
/// - 构造函数类型 `Function(param_types, ret_ty)`
/// - 创建函数名称
///
/// ### 2. 进入函数作用域
/// - 使用 `enter_scope()` 创建新的作用域
/// - 为函数参数提供独立的作用域
///
/// ### 3. 参数处理和函数体转换
/// - 处理参数列表，为每个参数创建 Name
/// - 使用 `block_expr_to_knf` 转换函数体
/// - 在转换过程中，`lookup_name` 会自动记录捕获的变量
///
/// ### 4. 退出作用域并构造闭包
/// - 使用 `exit_scope()` 退出函数作用域
/// - 获取捕获的变量映射
/// - 返回 `KnfClosure` 结构
///
/// ## 🔧 关键实现细节
///
/// ### 变量捕获机制
/// 这是局部函数转换的**核心难点**：
/// - 当局部函数访问外部变量时，需要"捕获"这些变量
/// - 捕获的变量需要存储在闭包中
/// - 需要修改 `lookup_name` 函数的作用方式
///
/// ### 捕获记录策略
/// 当一个变量在局部环境内没有找到时：
/// - 它应该向它的父环境进行寻找
/// - 如果找到，需要记录捕获
/// - 如果父环境没有找到，父环境的父环境找到了
/// - 那么父环境也需要记录捕获
///
/// ### 作用域链遍历
/// 变量查找需要沿着作用域链向上遍历：
/// - 当前作用域 -> 父作用域 -> 父父作用域 -> ...
/// - 每个找到变量的作用域都需要记录捕获
/// - 确保所有必要的变量都被正确捕获
///
/// ### 闭包构造
/// 闭包需要包含：
/// - 函数名称和参数
/// - 返回类型
/// - 函数体
/// - 捕获的变量映射
///
/// ## 📝 测试用例解析
///
/// ### 测试用例：嵌套局部函数
/// fn foo() -> Unit {
///   let x = 1;
///   fn bar() -> Unit {
///     fn baz() -> Unit {
///       print_int(x);  // baz 捕获 x
///     }
///     baz();
///   }
///   bar();
/// }
///
/// 转换过程：
/// 1. `foo` 函数：定义变量 x
/// 2. `bar` 函数：捕获 x（因为 baz 需要访问 x）
/// 3. `baz` 函数：捕获 x（直接访问 x）
/// 4. 每个闭包都记录其捕获的变量
///
/// ### 捕获分析
/// - `bar` 闭包：captured_vars = {x: Int}
/// - `baz` 闭包：captured_vars = {x: Int}
/// - 两个闭包都捕获了同一个变量 x
///
/// ## 💡 设计思想
///
/// ### 闭包概念
/// 局部函数形成闭包，可以访问外部函数的变量。
///
/// ### 变量捕获
/// 需要自动识别和记录被捕获的变量。
///
/// ### 作用域链
/// 变量查找需要沿着作用域链进行。
///
/// ### 嵌套支持
/// 支持多层嵌套的局部函数。
///
/// ## 🚀 实现挑战
///
/// ### 捕获识别
/// 这是**最大的难点**：
/// - 需要识别哪些变量被局部函数访问
/// - 需要记录捕获的变量
/// - 需要处理嵌套的作用域
///
/// ### 作用域管理
/// 需要正确管理嵌套的作用域：
/// - 进入和退出作用域的时机
/// - 作用域链的维护
/// - 捕获变量的记录
///
/// ### 变量查找
/// 需要修改 `lookup_name` 函数：
/// - 当变量在局部环境内没有找到时
/// - 向父环境进行寻找
/// - 记录捕获信息
/// - 处理多层嵌套的情况
///
/// ### 闭包构造
/// 需要正确构造闭包：
/// - 包含所有必要的信息
/// - 正确记录捕获的变量
/// - 保持作用域的完整性
///
/// ## 🎯 实现目标
///
/// 完成 `closure.mbt` 中的 `local_function_to_knf` 函数，实现局部函数的 KNF 转换。
/// 函数应该：
/// 1. 正确构造函数类型和名称
/// 2. 正确管理函数作用域
/// 3. 正确处理参数列表
/// 4. 正确转换函数体
/// 5. 正确记录捕获的变量
/// 6. 返回完整的 KnfClosure 结构
///
/// ## 🤔 思考题
///
/// 如何修改 `lookup_name` 函数来支持变量捕获？
/// - 当一个变量在局部环境内没有找到时，应该如何处理？
/// - 如何记录捕获的变量？
/// - 如何处理多层嵌套的作用域？
/// - 如何确保所有必要的变量都被正确捕获？
///
/// 现在让我们开始实现局部函数的转换吧！🚀
///
/// ================================================================================

///|
test "Local Function Knf Transformation Test" {
  // Prelude Parts
  let typecheck_ctx = @typecheck.Context::new()
  let knf_ctx = @knf.Context::new()

  // Setup builtin functions
  typecheck_ctx.func_types.set("print_int", Function([Int], Unit))
  typecheck_ctx.type_env.set("print_int", {
    kind: Function([Int], Unit),
    mutable: false,
  })
  // Typecheck ctx need to know about 'foo' ahead of time.
  // So that we can call `check_top_function` directly.
  typecheck_ctx.func_types.set("foo", Function([], Unit))
  knf_ctx.globals.set("print_int", Function([Int], Unit))
  let code =
    #|fn foo() -> Unit {
    #|  let x = 1;
    #|  fn bar() -> Unit {
    #|    fn baz() -> Unit {
    #|      print_int(x);
    #|    }
    #|    baz();
    #|  }
    #|  bar();
    #|}
  let tokens = @lexer.tokenize(code)
  let (top_func, _) = @parser.parse_top_function(tokens)
  let typechecked_func = typecheck_ctx.check_top_function(top_func)
  let knf_func = knf_ctx.top_function_to_knf(typechecked_func)
  assert_true(knf_func.body.stmts.length() is 3)
  // Second statement is local function 'bar'

  assert_true(
    knf_func.body.stmts[1] is ClosureDef(closure) && // closure 'bar'
    closure.captured_vars.length() is 1 && // bar captures 'x'
    closure.body.stmts is [s1, _] &&
    s1 is ClosureDef(inner_closure) && // inner closure 'baz'
    inner_closure.captured_vars.length() is 1, // baz captures 'x' from bar
  )
}
