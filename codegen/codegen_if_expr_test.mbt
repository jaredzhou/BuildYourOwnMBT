/// ================================================================================
/// # LLVM Codegen: if-else 与 PHI 节点
/// ================================================================================
///
/// 我们即将处理第一个真正的控制流结构：`if-else` 表达式。
/// 这在代码生成中是一个飞跃，因为它打破了指令的线性执行流程，并引入了一个强大的新概念：**PHI 节点**。
///
/// ## `if-else` 的控制流
///
/// `if-else` 语句在 LLVM IR 中通过一系列基本块和分支指令来表示：
///
/// 1.  **入口块 (`entry_bb`)**: 计算 `if` 的条件，然后根据结果使用 `createCondBr` 指令跳转到 `then_bb` 或 `else_bb`。
/// 2.  **Then 块 (`then_bb`)**: 包含 `if` 为真时执行的代码。
/// 3.  **Else 块 (`else_bb`)**: 包含 `if` 为假时执行的代码。
/// 4.  **合并块 (`merge_bb`)**: `then` 和 `else` 分支执行完毕后，控制流会重新汇合到这个块，继续执行后续代码。
///
/// ## 💡 核心概念：PHI 节点
///
/// 考虑表达式 `let z = if cond { x } else { y }`。当控制流到达 `merge_bb` 时，`z` 的值是什么？
/// 它可能是 `x`（如果走了 `then` 分支），也可能是 `y`（如果走了 `else` 分支）。
///
/// 为了在 SSA 形式下解决这个问题（一个变量只能被赋值一次），LLVM 引入了 `phi` 指令。
///
/// **PHI 节点就像一个根据来源路径选择值的开关**。
///
/// `z = phi i32 [ %x, %then_bb ], [ %y, %else_bb ]`
///
/// 这行代码的意思是：
/// - `z` 的值是一个 `i32`。
/// - 如果控制流是从 `%then_bb` 过来的，`z` 的值就等于 `%x`。
/// - 如果控制流是从 `%else_bb` 过来的，`z` 的值就等于 `%y`。
///
/// ## 🎯 你的任务
///
/// 本次挑战的目标是实现 `if_codegen` 函数，使其能够正确处理 `if-else` 表达式。
///
/// ### 1. 创建基本块和分支
///
/// - 如上所述，为 `then`、`else` 和 `merge` 创建三个新的基本块。
/// - 生成 `createCondBr` 指令进行条件跳转。
///
/// ### 2. 实现 PHI 节点逻辑
///
/// - 如果 `if` 表达式有返回值（即它的类型不是 `Unit`），你需要在 `merge_bb` 的**最开始**创建一个 PHI 节点。
///   - **接口**: `builder.createPHI(type)`
/// - 在分别生成完 `then` 块和 `else` 块的代码后，你需要告诉 PHI 节点这两个分支分别会产生什么值。
///   - **接口**: `phi_node.addIncoming(value, block)`
///
/// ### 3. ⚠️ 注意：处理已终结的块
///
/// 在 `then` 块或 `else` 块的末尾，我们通常需要一个 `createBr` 指令跳转到 `merge_bb`。
/// 但是，如果这个块已经因为一个 `return` 指令而“终结”了呢？在一个基本块中添加两个终结指令是错误的。
///
/// - 在添加 `br` 指令前，你必须检查当前块是否已经有了终结指令。
///   - **接口**: `builder.getInsertBlock().getTerminator()`。如果返回值是 `Some(...)`，则说明已有终结指令，不应再添加 `br`。
///
/// ### 4. ⚠️ 特别当心：无用的 `merge` 块
///
/// 考虑这种情况：`fn max(a, b) { if a > b { return a; } else { return b; } }`
///
/// 在这里，`then` 块和 `else` 块都以 `return` 结束。控制流**永远不会**到达 `merge_bb`。
/// 这种情况下，`merge_bb` 成了一个没有前驱（predecessor）的“死块”。一个没有前驱的基本块是非法的（入口块除外）。
///
/// - 你需要检测这种情况（即 `then` 和 `else` 块都已被终结）。
/// - 如果发生，你应该将 `merge_bb` 从函数中移除，以保持 IR 的合法性。
///   - **接口**: `merge_bb.removeFromParent()`
///
/// ---
///
/// 这是一个复杂的挑战，但它涵盖了代码生成中关于控制流的许多核心思想。
///
/// 跟着下面的指引完成任务吧。

///|
///
test "Codegen for If Test" {
  let code =
    #|fn max(x: Int, y: Int) -> Int {
    #|  let z = if x > y { x } else { y };
    #|  z
    #|}
    #|
    #|fn min(x: Int, y: Int) -> Int {
    #|  if x < y {
    #|    return x;
    #|  } else {
    #|    return y;
    #|  }
    #|}
    #|
    #|fn mid(x: Int, y: Int) -> Int {
    #|  if x < y {
    #|    return x;
    #|  } else {
    #|     2
    #|  }
    #|  return y;
    #|}
    #|
  let tokens = @lexer.tokenize(code)
  let ast = @parser.parse(tokens)
  let typed_ast = @typecheck.typecheck(ast)
  let knf_prog = @knf.knf_transform(typed_ast)
  let codegen_ctx = Context::new("demo")
  codegen_ctx.collect_func_values(knf_prog.functions)

  // max
  let max = knf_prog.functions.get("max").unwrap()
  let llvm_func = codegen_ctx.top_function_codegen(max)
  inspect(
    llvm_func,
    content=(
      #|define i32 @max(ptr %0, i32 %1, i32 %2) {
      #|entry:
      #|  %3 = icmp sgt i32 %1, %2
      #|  br i1 %3, label %5, label %7
      #|
      #|5:                                     ; preds = %entry
      #|  br label %9
      #|
      #|7:                                     ; preds = %entry
      #|  br label %9
      #|
      #|9:                                     ; preds = %5, %7
      #|  %10 = phi i32 [ %1, %5 ], [ %2, %7 ]
      #|  ret i32 %10
      #|}
      #|
    ),
  )

  // min
  let min = knf_prog.functions.get("min").unwrap()
  let llvm_func = codegen_ctx.top_function_codegen(min)
  inspect(
    llvm_func,
    content=(
      #|define i32 @min(ptr %0, i32 %1, i32 %2) {
      #|entry:
      #|  %3 = icmp slt i32 %1, %2
      #|  br i1 %3, label %5, label %7
      #|
      #|5:                                     ; preds = %entry
      #|  ret i32 %1
      #|
      #|7:                                     ; preds = %entry
      #|  ret i32 %2
      #|}
      #|
    ),
  )

  //mid
  let mid = knf_prog.functions.get("mid").unwrap()
  let llvm_func = codegen_ctx.top_function_codegen(mid)
  inspect(
    llvm_func,
    content=(
      #|define i32 @mid(ptr %0, i32 %1, i32 %2) {
      #|entry:
      #|  %3 = icmp slt i32 %1, %2
      #|  br i1 %3, label %5, label %7
      #|
      #|5:                                     ; preds = %entry
      #|  ret i32 %1
      #|
      #|7:                                     ; preds = %entry
      #|  br label %9
      #|
      #|9:                                     ; preds = %7
      #|  %10 = phi i32 [ 2, %7 ]
      #|  ret i32 %2
      #|}
      #|
    ),
  )
}
