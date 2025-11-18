/// ================================================================================
/// # LLVM Codegen: 创建数组
/// ================================================================================
///
/// 我们已经可以处理基本类型和变量了。现在，我们来处理第一个复合类型：**数组（Array）**。
/// 我们从数组的创建 `Array::make(size, init)` 开始。
///
/// ## 堆分配 vs. 栈分配
///
/// **⚠️ 重要概念提醒**:
///
/// - **栈（Stack）**: 用于存放函数调用期间的局部变量（比如我们用 `let mut` 创建的变量）。内存由编译器自动管理，函数返回时自动释放。我们使用 `alloca` 指令在栈上分配内存。
/// - **堆（Heap）**: 用于存放生命周期更长、大小可能在运行时才确定的数据（比如数组、结构体实例）。内存需要手动管理（在我们的编译器中，通过调用一个简单的运行时库来模拟 `malloc`）。
///
/// 在我们的 MiniMoonBit 语言中，**数组和结构体都存放在堆上**。因此，我们**不应该**使用 `alloca` 来为数组分配空间。
///
/// ## 🎯 你的任务
///
/// 本次挑战的目标是扩展 `expr_codegen` 函数，使其能够处理 `KnfExpr::ArrayMake` 表达式。
///
/// ## 💡 实现指南
///
/// 你需要调用一个定义在 `runtime.c` 中、并通过 `Context` 预先声明好的**内建函数（Builtin Function）**来在堆上创建数组。
///
/// 1.  **查找内建函数**:
///     在 `codegen/context.mbt` 中，我们已经为你声明了一系列用于创建数组的内建函数，例如 `make_int_array`, `make_double_array` 等，并将它们存储在了 `builtin_funcs` 这个 `Map` 中。
///
/// 2.  **根据类型选择**:
///     在 `expr_codegen` 中处理 `ArrayMake(size_name, init_name)` 时，你需要：
///     a. 检查 `init_name` 对应的 KNF 类型。
///     b. 根据这个类型，从 `builtin_funcs` 中选择正确的创建函数。例如，如果类型是 `Int`，你就需要查找名为 `"make_int_array"` 的函数。
///
/// 3.  **生成调用指令**:
///     a. 获取 `size` 和 `init` 对应的 LLVM 值。
///     b. 使用 `builder.createCall(make_array_func, [size_value, init_value])` 来生成调用指令。
///
/// ---
///
/// 本次测试 `codegen_array_make_test.mbt` 将检查你是否能为一个 `Array::make` 表达式正确生成对内建函数的调用。
///
/// 跟着下面的指引完成任务吧。

test "Codegen for Array Make Test" {

  let code = 
    #|fn make_arr(x: Int) -> Array[Int] {
    #|  let arr = Array::make(x, 0);
    #|  arr
    #|}

  let tokens = @lexer.tokenize(code)
  let ast = @parser.parse(tokens)
  let typed_ast = @typecheck.typecheck(ast)
  let knf_prog = @knf.knf_transform(typed_ast)
  let codegen_ctx = Context::new("demo")
  codegen_ctx.collect_func_values(knf_prog.functions)

  // make_arr
  let make_arr = knf_prog.functions.get("make_arr").unwrap()
  let llvm_func = codegen_ctx.top_function_codegen(make_arr)
  inspect(llvm_func, content=(
    
    #|define ptr @make_arr(ptr %0, i32 %1) {
    #|entry:
    #|  %2 = call ptr @make_int_array(i32 %1, i32 0)
    #|  ret ptr %2
    #|}
    #|
  ))
}