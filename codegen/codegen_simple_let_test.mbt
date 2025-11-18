///|
/// ================================================================================
/// # LLVM Codegen: let 和 let mut
/// ================================================================================
///
/// 我们已经能为简单的返回值生成代码了。现在，我们来处理变量绑定：`let` 和 `let mut` 语句。
/// 这两种语句在代码生成阶段的处理方式有着本质的区别。
///
/// ## `let` 语句（不可变绑定）
///
/// `let z = x;`
///
/// 在 KNF 和 SSA 的世界里，`let` 语句通常不产生新的 LLVM 指令。
/// 因为 `x` 已经是一个计算好的 LLVM 值（可以看作一个“寄存器”里的值），
/// 我们要做的仅仅是在我们的 `Context` 中建立一个新的映射，将 `z` 这个名字指向 `x` 对应的那个 LLVM 值。
///
/// ``` skip
/// In let_stmt_codegen:
/// let value = self.expr_codegen(expr).unwrap();
/// self.name_values.set(name, value); // 将新名字映射到已有的 LLVM 值
/// ```
///
/// ## `let mut` 语句（可变绑定）
///
/// `let mut z = x;`
///
/// 可变变量需要一个可以被反复读写的内存地址。在函数中，这通常是在栈（Stack）上分配的。
///
/// 1.  **分配内存 (`alloca`)**: 我们需要使用 `builder.createAlloca(type)` 指令在函数栈上为变量 `z` 分配一块内存。
/// 2.  **存储初始值 (`store`)**: 接着，使用 `builder.createStore(value, ptr)` 指令将 `x` 的值存入刚刚分配的内存地址中。
/// 3.  **更新映射**: 在 `Context` 中，我们将名字 `z` 映射到 `alloca` 指令返回的**指针**。
///
/// ## 🎯 你的任务
///
/// 本次挑战的核心是实现 `let_stmt_codegen` 和 `let_mut_stmt_codegen`，并修改 `expr_codegen` 以正确处理变量的加载。
///
/// ### 1. 实现 `let_stmt_codegen` 和 `let_mut_stmt_codegen`
///
/// 在 `codegen/top_function.mbt` 中实现这两个函数，遵循上面描述的逻辑。
///
/// ### 2. 修改 `expr_codegen` 中对 `Ident` 的处理
///
/// **⚠️ 这是本次挑战的关键，也是需要特别当心的地方！**
///
/// 当 `expr_codegen` 遇到一个变量（`Ident(name)`）时，它需要从 `name_values` 中查找对应的 LLVM 值。但现在存在两种可能：
///   - 这个值是一个普通的 SSA 值（来自 `let` 绑定或计算结果）。
///   - 这个值是一个指向栈内存的指针（来自 `let mut` 的 `alloca`）。
///
/// 你需要区分这两种情况。如果值是一个 `alloca` 指针，你必须在使用它之前，先用 `builder.createLoad(type, ptr)` 指令从内存中把真实的值加载出来。
///
/// **提示**: 你可以通过 `value.asValueEnum() is AllocaInst(_)` 来判断一个 `@llvm.Value` 是否是 `alloca` 指令的结果。
///
/// 本次测试 `codegen_simple_let_test.mbt` 将检查你是否能为 `let` 和 `let mut` 正确生成代码。
///
/// 跟着下面的指引完成任务吧。
test "Codegen for Simple Let and LetMut Test" {
  let code =
    #|fn foo(x: Int) -> Int {
    #|  let z = x;
    #|  z
    #|}
    #|
    #|fn bar(x: Int) -> Int {
    #|  let mut z = x;
    #|  z
    #|}
  let tokens = @lexer.tokenize(code)
  let ast = @parser.parse(tokens)
  let typed_ast = @typecheck.typecheck(ast)
  let knf_prog = @knf.knf_transform(typed_ast)
  let codegen_ctx = Context::new("demo")
  codegen_ctx.collect_func_values(knf_prog.functions)

  // foo
  let add = knf_prog.functions.get("foo").unwrap()
  let llvm_func = codegen_ctx.top_function_codegen(add)
  inspect(
    llvm_func,
    content=(
      #|define i32 @foo(ptr %0, i32 %1) {
      #|entry:
      #|  ret i32 %1
      #|}
      #|
    ),
  )
  println("ok with foo")
  // bar
  let bar = knf_prog.functions.get("bar").unwrap()
  let llvm_func2 = codegen_ctx.top_function_codegen(bar)
  inspect(
    llvm_func2,
    content=(
      #|define i32 @bar(ptr %0, i32 %1) {
      #|entry:
      #|  %2 = alloca i32, align 4
      #|  store i32 %1, ptr %2, align 4
      #|  %4 = load i32, ptr %2, align 4
      #|  ret i32 %4
      #|}
      #|
    ),
  )
}
