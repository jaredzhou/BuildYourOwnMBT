/// ================================================================================
/// # LLVM Codegen: 数组字面量
/// ================================================================================
///
/// 我们已经学习了 `Array::make`，现在我们来处理另一种更直观的数组创建方式：**数组字面量（Array Literals）**，例如 `[1, 2, 3]`。
///
/// ## 🎯 你的任务
///
/// 本次挑战的目标是扩展 `expr_codegen` 函数，使其能够处理 `KnfExpr::ArrayLiteral` 表达式。
///
/// ## 💡 实现指南：三步走
///
/// 生成数组字面量的代码可以分解为三个步骤：
///
/// 1.  **创建空数组**:
///     首先，调用我们之前实现的 `make_..._array` 内建函数来创建一个指定大小但内容为默认值的数组。
///     - **大小**: 数组字面量中的元素数量。
///     - **初始值**: 可以是该类型的任意默认值（例如 `0` 或 `false`），因为它马上就会被覆盖。
///
/// 2.  **逐个填充元素**:
///     遍历数组字面量中的每一个元素。对于每个元素，生成一个 `array_..._put` 调用，
///     将元素的值设置到数组对应的索引位置上。
///
/// 3.  **返回数组**:
///     最后，返回第一步中创建的数组的指针。
///
/// 简单来说，`[1, 2, 3]` 的代码生成逻辑等价于：
///
/// ```skip
/// let __internal_array = Array::make(3, 0); // 步骤 1
/// __internal_array[0] = 1;                  // 步骤 2
/// __internal_array[1] = 2;
/// __internal_array[2] = 3;
/// __internal_array;                         // 步骤 3
/// ```
///
/// 同样，你需要根据数组的元素类型，从 `Context` 的 `builtin_funcs` 中选择正确的 `make` 和 `put` 函数，并使用 `createCall` 来调用它们。
///
/// ---
///
/// 本次测试 `codegen_array_expr_test.mbt` 将检查你是否能为数组字面量正确生成创建和填充指令。
///
/// 跟着下面的指引完成任务吧。

test "Codegen for Array Literal Test" {

  let code = 
    #|fn create_arr() -> Array[Int] {
    #|  [1, 2, 3];
    #|}

  let tokens = @lexer.tokenize(code)
  let ast = @parser.parse(tokens)
  let typed_ast = @typecheck.typecheck(ast)
  let knf_prog = @knf.knf_transform(typed_ast)
  let codegen_ctx = Context::new("demo")
  codegen_ctx.collect_func_values(knf_prog.functions)

  // codegen
  let create_arr = knf_prog.functions.get("create_arr").unwrap()
  let llvm_func = codegen_ctx.top_function_codegen(create_arr)
  inspect(llvm_func, content=(
    
    #|define ptr @create_arr(ptr %0) {
    #|entry:
    #|  %1 = call ptr @make_int_array(i32 3, i32 0)
    #|  call void @array_int_put(ptr %1, i32 0, i32 1)
    #|  call void @array_int_put(ptr %1, i32 1, i32 2)
    #|  call void @array_int_put(ptr %1, i32 2, i32 3)
    #|  ret ptr %1
    #|}
    #|

  ))
}
