/// ================================================================================
/// # LLVM Codegen: 数组的访问与更新
/// ================================================================================
///
/// 我们已经学会了如何创建数组。现在，我们来学习如何与数组进行交互：
/// 读取数组中的元素（`get`）和更新数组中的元素（`put`）。
///
/// ## 🎯 你的任务
///
/// 本次挑战的目标是扩展 `expr_codegen` 和 `stmt_codegen`，使其能够处理：
/// 1.  **数组访问表达式** (`KnfExpr::ArrayAccess`)
/// 2.  **数组更新语句** (`KnfStmt::ArrayPut`)
///
/// ## 💡 实现指南：调用内建函数
///
/// 与数组创建一样，对数组的访问和更新也是通过调用 `Context` 中预先定义好的内建函数来完成的。
/// 你需要做的就是根据数组的元素类型，选择正确的函数并使用 `builder.createCall` 来调用它。
///
/// ### 数组元素访问 (Get)
///
/// 在 `expr_codegen` 中处理 `ArrayAccess(array_name, index_name)` 时：
///
/// 1.  **确定类型**: 检查 `array_name` 的 KNF 类型，确定其元素类型（如 `Int`, `Double` 等）。
/// 2.  **选择函数**: 根据元素类型，从 `builtin_funcs` 中获取对应的 `get` 函数（如 `"array_int_get"`）。
/// 3.  **生成调用**: 使用 `createCall` 生成对该函数的调用，参数为数组的指针和索引值。
///
/// ### 数组元素更新 (Put)
///
/// 在 `stmt_codegen` 中添加一个新的分支来处理 `ArrayPut(array_name, index_name, value_expr)` 语句：
///
/// 1.  **计算右值**: 首先，调用 `expr_codegen` 计算出 `value_expr` 的 LLVM 值。
/// 2.  **确定类型**: 检查 `array_name` 的 KNF 类型以确定元素类型。
/// 3.  **选择函数**: 根据元素类型，从 `builtin_funcs` 中获取对应的 `put` 函数（如 `"array_int_put"`）。
/// 4.  **生成调用**: 使用 `createCall` 生成调用，参数为数组指针、索引值和要存入的新值。
///
/// ---
///
/// 本次测试 `codegen_array_acc_and_put_test.mbt` 将检查你是否能正确生成对 `get` 和 `put` 内建函数的调用。
///
/// 跟着下面的指引完成任务吧。

test "Codegen for Array Make Test" {

  let code = 
    #|fn swap_head_two(arr: Array[Int]) -> Unit {
    #|  let t = arr[0];
    #|  arr[0] = arr[1];
    #|  arr[1] = t;
    #|}

  let tokens = @lexer.tokenize(code)
  let ast = @parser.parse(tokens)
  let typed_ast = @typecheck.typecheck(ast)
  let knf_prog = @knf.knf_transform(typed_ast)
  let codegen_ctx = Context::new("demo")
  codegen_ctx.collect_func_values(knf_prog.functions)

  // make_arr
  let swap_head_two = knf_prog.functions.get("swap_head_two").unwrap()
  let llvm_func = codegen_ctx.top_function_codegen(swap_head_two)
  inspect(llvm_func, content=(
    #|define void @swap_head_two(ptr %0, ptr %1) {
    #|entry:
    #|  %2 = call i32 @array_int_get(ptr %1, i32 0)
    #|  %3 = call i32 @array_int_get(ptr %1, i32 1)
    #|  call void @array_int_put(ptr %1, i32 0, i32 %3)
    #|  call void @array_int_put(ptr %1, i32 1, i32 %2)
    #|  ret void
    #|}
    #|


  ))
}