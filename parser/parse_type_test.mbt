/// ================================================================================
/// # 语法解析的另一分支：解析类型
///
/// 恭喜你！你已经征服了表达式解析中最艰难、最核心的部分。
/// 现在，让我们将目光从“值”的世界暂时移开，转向“类型”的世界。
///
/// 在 `parser/typedef.mbt` 中，你需要实现 `parse_type` 函数，
/// 它负责将 Token 序列解析为 MiniMoonBit 中的各种类型，例如 `Int`、`Array[Bool]`、`(Int, Double) -> Bool` 等。
///
/// 相信在经历了表达式解析的重重考验之后，类型的解析对你来说应该已经是小菜一碟了。
/// 它的逻辑与解析表达式有许多相似之处，但通常更简单，因为它不涉及运算符优先级等复杂问题。
///
/// 因此，这个挑战的教程就不再做过多展开了，请你尽情施展吧！
///
/// 加油！💪
///
/// **阶段性测试：**
///
/// ```bash
/// moon test -p parser -f parse_type_test.mbt
/// ```
/// ================================================================================

///|
test "Simple Type Parsing" {
  let code =
    #|Unit Int Bool Double
  let tokens = @lexer.tokenize(code)
  let (ty, tok_view) = parse_type(tokens[:])
  assert_true(ty.kind is Unit)
  let (ty, tok_view) = parse_type(tok_view)
  assert_true(ty.kind is Int)
  let (ty, tok_view) = parse_type(tok_view)
  assert_true(ty.kind is Bool)
  let (ty, _) = parse_type(tok_view)
  assert_true(ty.kind is Double)
}

///|
test "Complex Type Parsing" {
  let code =
    #|Array[Int]
    #|(Int, Double) 
    #|() -> Double
    #|((Int, Double), Unit)
    #|(Array[Bool], Unit) -> Double
    #|Array[(Int, Double)]
    #|Array[() -> Double]
    #|Array[((Int, Double), Unit)]
  let tokens = @lexer.tokenize(code)
  let (ty, tok_view) = parse_type(tokens[:])
  assert_true(ty.kind is Array(Int))
  let (ty, tok_view) = parse_type(tok_view)
  assert_true(ty.kind is Tuple([Int, Double]))
  let (ty, tok_view) = parse_type(tok_view)
  assert_true(ty.kind is Function([], Double))
  let (ty, tok_view) = parse_type(tok_view)
  assert_true(ty.kind is Tuple([Tuple([Int, Double]), Unit]))
  let (ty, tok_view) = parse_type(tok_view)
  assert_true(ty.kind is Function([Array(Bool), Unit], Double))
  let (ty, tok_view) = parse_type(tok_view)
  assert_true(ty.kind is Array(Tuple([Int, Double])))
  let (ty, tok_view) = parse_type(tok_view)
  assert_true(ty.kind is Array(Function([], Double)))
  let (ty, _) = parse_type(tok_view)
  assert_true(ty.kind is Array(Tuple([Tuple([Int, Double]), Unit])))
}