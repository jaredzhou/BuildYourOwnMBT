///|
///
/// 注意这里的expr_codegen的返回值是Option[&@llvm.Value]
/// 对于Unit类型的表达式，应当返回None做特殊处理。
///
/// 对于像let a: Unit = (); 这种表达式，可以考虑把a的值设为null指针，
/// 使用llvm_ctx.getConstPointerNull(llvm_ctx.getPtrTy())
pub fn Context::expr_codegen(
  self : Self,
  expr : @knf.KnfExpr,
) -> &@llvm.Value? raise {
  // println("expr codegen: \{expr}")
  match expr {
    Int(i) => (self.llvm_ctx.getConstInt32(i) : &@llvm.Value) |> Some
    Double(d) => (self.llvm_ctx.getConstDouble(d) : &@llvm.Value) |> Some
    Bool(b) => (self.llvm_ctx.getConstBool(b) : &@llvm.Value) |> Some
    String(s) => {
      let str = self.builder.createGlobalString(
        s,
        name="str_lit_\{self.str_cnt}",
      )
      self.str_cnt += 1
      (str : &@llvm.Value) |> Some
    }
    Ident(name) => {
      let value = self.name_values.get(name)
      value.map(value => if value.asValueEnum() is AllocaInst(ptr) {
        self.builder.createLoad(ptr.data_ty, ptr)
      } else {
        value
      })
    }
    Not(name) => {
      let value = self.expr_codegen(Ident(name))
      value.map(value => self.builder.createXor(
        self.llvm_ctx.getConstTrue(),
        value,
      ))
    }
    Neg(name) => {
      let value = self.expr_codegen(Ident(name))
      value.map(value => if value.getType().isIEEELikeFPTy() {
        self.builder.createFNeg(value)
      } else {
        self.builder.createSub(self.llvm_ctx.getConstInt32(0), value)
      })
    }
    Binary(op, left, right) => self.binary_expr_codegen(op, left, right)
    ArrayMake(size_name, init_name) => {
      let init_ty = self.name_types.get(init_name)
      guard init_ty is Some(init_ty) else {
        raise CodegenError("init_name not found: \{init_name}")
      }
      let make_func = self.get_make_array_func(init_ty)
      let size = self.get_concrete_value(size_name).unwrap()
      let init = self.get_opaque_value(init_name).unwrap()
      (self.builder.createCall(make_func, [size, init]) : &@llvm.Value) |> Some
    }
    ArrayAccess(array_name, index_name) => {
      let array_ty = self.name_types.get(array_name).unwrap()
      guard array_ty is Array(elem_ty) else {
        raise CodegenError("array_name not found: \{array_name}")
      }
      let array = self.get_opaque_value(array_name).unwrap()
      let index = self.get_concrete_value(index_name).unwrap()
      let get_func = self.get_array_get_func(elem_ty)
      println("create call: \{get_func} with args: \{array} and \{index}")
      (self.builder.createCall(get_func, [array, index]) : &@llvm.Value) |> Some
    }
    ArrayLiteral(ty, names) => self.array_literal_codegen(ty, names)
    Block(block) => self.block_codegen(block)
    If(cond, then_block, else_block) =>
      self.if_codegen(cond, then_block, else_block)
    CreateStruct(name, fields) => self.create_struct_codegen(name, fields)
    FieldAccess(struct_name, field_name) =>
      self.field_access_codegen(struct_name, field_name)
    TupleAccess(tuple_name, index) =>
      self.tuple_access_codegen(tuple_name, index)
    TupleLiteral(names) => self.tuple_codegen(names)
    Call(func_name, args) => self.call_codegen(func_name, args)
    e => raise CodegenError("Unsupported expression in codegen: \{e}")
  }
}

///|
/// 暂时就当没有间接函数类型赋值
/// 所以可以认为String(func_name) = @knf.Name.id
fn Context::call_codegen(
  self : Self,
  func_name : @knf.Name,
  args : Array[@knf.Name],
) -> &@llvm.Value? raise {
  let args_values = args.map(arg => {
    let value = self.get_concrete_value(arg)
    guard value is Some(value) else {
      raise CodegenError("call expr_codegen returned None: \{arg}")
    }
    value
  })
  let nil_pointer = (
    self.llvm_ctx.getConstPointerNull(self.llvm_ctx.getPtrTy()) : &@llvm.Value)
  match self.builtin_funcs.get(func_name.id) {
    Some(func) =>
      (self.builder.createCall(func, args_values) : &@llvm.Value) |> Some
    None =>
      match self.functions.get(func_name.id) {
        Some(func) =>
          (
            self.builder.createCall(func, [nil_pointer] + args_values) :
            &@llvm.Value)
          |> Some
        None =>
          match self.name_values.get(func_name) {
            Some(value) =>
              match value.asValueEnum() {
                Function(func) =>
                  (
                    self.builder.createCall(func, [nil_pointer] + args_values) :
                    &@llvm.Value)
                  |> Some
                _ => {
                  // Function pointer case: value is a pointer to a function
                  let func_ty = self.name_types.get(func_name)
                  guard func_ty is Some(Function(knf_param_types, knf_ret_type)) else {
                    raise CodegenError(
                      "value is not a Function type: \{func_name.id}",
                    )
                  }
                  let ptrty = self.llvm_ctx.getPtrTy()
                  let param_types : Array[&@llvm.Type] = [ptrty]
                  knf_param_types.each(ty => {
                    let llvm_param_type = self.type_codegen_opaque(ty)
                    param_types.push(llvm_param_type)
                  })
                  let llvm_ret_type = self.type_codegen_opaque(knf_ret_type)
                  let llvm_fty = self.llvm_ctx.getFunctionType(
                    llvm_ret_type, param_types,
                  )
                  guard llvm_fty.asTypeEnum() is FunctionType(fty) else {
                    raise CodegenError(
                      "failed to get FunctionType: \{func_name.id}",
                    )
                  }
                  println("creating callPtr with value: \{value}, fty: \{fty}")
                  println("args_values: \{args_values}")
                  let ret = self.builder.createCallPtr(
                    value,
                    fty,
                    [nil_pointer] + args_values,
                  )
                  println("ret: \{ret}")
                  Some(ret)
                }
              }
            None => raise CodegenError("func not found: \{func_name.id}")
          }
      }
  }
}

///|
fn Context::tuple_codegen(
  self : Self,
  names : Array[@knf.Name],
) -> &@llvm.Value? raise {
  let tuple_types = names.map(name => self.type_codegen_concrete(
    self.name_types.get(name).unwrap(),
  ))
  let tuple_ty = self.llvm_ctx.getStructType(tuple_types)
  let tuple_size = self.llvm_mod.getDataLayout().getTypeAllocSize(tuple_ty)
  let malloc_func = self.builtin_funcs.get("moonbit_malloc").unwrap()
  let tuple_ptr = self.builder.createCall(malloc_func, [
    self.llvm_ctx.getConstInt32(tuple_size),
  ])
  names.eachi((i, name) => {
    let value = self.expr_codegen(Ident(name))
    guard value is Some(value) else {
      raise CodegenError("expr_codegen returned None: \{name}")
    }
    let field_address = self.builder.createGEP(tuple_ptr, tuple_ty, [
      self.llvm_ctx.getConstInt32(0),
      self.llvm_ctx.getConstInt32(i),
    ])
    let _ = self.builder.createStore(value, field_address)

  })
  (tuple_ptr : &@llvm.Value) |> Some
}

///|
fn Context::tuple_access_codegen(
  self : Self,
  tuple_name : @knf.Name,
  index : Int,
) -> &@llvm.Value? raise {
  let tuple_ptr = self.name_values.get(tuple_name).unwrap()
  let knf_tuple_ty = self.name_types.get(tuple_name).unwrap()
  guard knf_tuple_ty is Tuple(elem_types) else {
    raise CodegenError("tuple_name is not a tuple")
  }
  let elem_types = elem_types.map(elem_type => self.type_codegen_concrete(
    elem_type,
  ))
  let tuple_ty = self.llvm_ctx.getStructType(elem_types)
  let field_address = self.builder.createGEP(tuple_ptr, tuple_ty, [
    self.llvm_ctx.getConstInt32(0),
    self.llvm_ctx.getConstInt32(index),
  ])
  self.builder.createLoad(elem_types[index], field_address) |> Some
}

///|
fn Context::create_struct_codegen(
  self : Self,
  name : String,
  fields : Array[(String, @knf.Name)],
) -> &@llvm.Value? raise {
  let struct_ty = self.struct_types.get(name).unwrap()
  let struct_size = self.llvm_mod.getDataLayout().getTypeAllocSize(struct_ty)
  let malloc_func = self.builtin_funcs.get("moonbit_malloc").unwrap()
  let struct_ptr = self.builder.createCall(malloc_func, [
    self.llvm_ctx.getConstInt32(struct_size),
  ])
  fields.eachi((i, field) => {
    let (field_name, value_name) = field
    let field_address = self.builder.createGEP(struct_ptr, struct_ty, [
      self.llvm_ctx.getConstInt32(0),
      self.llvm_ctx.getConstInt32(i),
    ])
    let value = self.expr_codegen(Ident(value_name))
    guard value is Some(value) else {
      raise CodegenError(
        "struct name \{name} field \{field_name} expr_codegen returned None",
      )
    }
    let _ = self.builder.createStore(value, field_address)

  })
  (struct_ptr : &@llvm.Value) |> Some
}

///|
fn Context::field_access_codegen(
  self : Self,
  struct_name : @knf.Name,
  field_name : String,
) -> &@llvm.Value? raise {
  let struct_ptr = self.name_values.get(struct_name).unwrap()
  let knf_struct_ty = self.name_types.get(struct_name).unwrap()
  guard knf_struct_ty is Struct(struct_ty_name) else {
    raise CodegenError("struct_var_name is not a struct")
  }
  let struct_ty = self.struct_types.get(struct_ty_name).unwrap()
  let knf_struct_def = self.knf_struct_types.get(struct_ty_name).unwrap()
  let field_index = knf_struct_def.get_field_index(field_name).unwrap()
  let field_address = self.builder.createGEP(struct_ptr, struct_ty, [
    self.llvm_ctx.getConstInt32(0),
    self.llvm_ctx.getConstInt32(field_index),
  ])
  let field_ty = self.type_codegen_concrete(
    knf_struct_def.fields.get(field_index).unwrap().2,
  )
  let field_value = self.builder.createLoad(field_ty, field_address)
  (field_value : &@llvm.Value) |> Some
}

///|
fn Context::array_literal_codegen(
  self : Self,
  ty : @knf.Type,
  names : Array[@knf.Name],
) -> &@llvm.Value? raise {
  // 创建默认值数组
  guard ty is Array(elem_ty) else { raise CodegenError("ty is not an array") }
  let default = self.get_default_value(elem_ty)
  let make_func = self.get_make_array_func(elem_ty)
  let size = self.llvm_ctx.getConstInt32(names.length())
  let array = self.builder.createCall(make_func, [size, default])

  //填充值
  let put_func = self.get_array_put_func(elem_ty)
  names.eachi((i, name) => {
    println("index: \{i} name: \{name}")
    let value = self.expr_codegen(Ident(name))
    guard value is Some(value) else {
      raise CodegenError("array literal expr_codegen returned None: \{name}")
    }
    let index = self.llvm_ctx.getConstInt32(i)
    let _ = self.builder.createCall(put_func, [array, index, value])

  })
  (array : &@llvm.Value) |> Some
}

///|
fn Context::get_make_array_func(
  self : Self,
  ty : @knf.Type,
) -> @llvm.Function raise {
  match ty {
    Int => self.builtin_funcs.get("make_int_array").unwrap()
    Double => self.builtin_funcs.get("make_double_array").unwrap()
    Bool => self.builtin_funcs.get("make_bool_array").unwrap()
    _ => self.builtin_funcs.get("make_ptr_array").unwrap()
  }
}

///|
fn Context::get_array_get_func(
  self : Self,
  ty : @knf.Type,
) -> @llvm.Function raise {
  match ty {
    Int => self.builtin_funcs.get("array_int_get").unwrap()
    Double => self.builtin_funcs.get("array_double_get").unwrap()
    Bool => self.builtin_funcs.get("array_bool_get").unwrap()
    _ => self.builtin_funcs.get("array_ptr_get").unwrap()
  }
}

///|
fn Context::get_array_put_func(
  self : Self,
  ty : @knf.Type,
) -> @llvm.Function raise {
  match ty {
    Int => self.builtin_funcs.get("array_int_put").unwrap()
    Double => self.builtin_funcs.get("array_double_put").unwrap()
    Bool => self.builtin_funcs.get("array_bool_put").unwrap()
    _ => self.builtin_funcs.get("array_ptr_put").unwrap()
  }
}

///|
fn Context::get_default_value(self : Self, ty : @knf.Type) -> &@llvm.Value {
  match ty {
    Int => (self.llvm_ctx.getConstInt32(0) : &@llvm.Value)
    Double => (self.llvm_ctx.getConstDouble(0.0) : &@llvm.Value)
    Bool => (self.llvm_ctx.getConstFalse() : &@llvm.Value)
    _ =>
      (
        self.llvm_ctx.getConstPointerNull(self.llvm_ctx.getPtrTy()) :
        &@llvm.Value)
  }
}

///|
pub fn Context::binary_expr_codegen(
  self : Self,
  op : @knf.BinaryOp,
  left : @knf.Name,
  right : @knf.Name,
) -> &@llvm.Value? raise {
  let left_value = self.expr_codegen(Ident(left))
  guard left_value is Some(left_value) else {
    raise CodegenError("expr_codegen returned None")
  }
  let right_value = self.expr_codegen(Ident(right))
  guard right_value is Some(right_value) else {
    raise CodegenError("expr_codegen returned None")
  }
  match op {
    Add =>
      Some(
        if left_value.getType().isIEEELikeFPTy() {
          self.builder.createFAdd(left_value, right_value)
        } else {
          self.builder.createAdd(left_value, right_value)
        },
      )
    Sub => {
      let value = if left_value.getType().isIEEELikeFPTy() {
        self.builder.createFSub(left_value, right_value)
      } else {
        self.builder.createSub(left_value, right_value)
      }
      Some(value)
    }
    Mul => {
      let value = if left_value.getType().isIEEELikeFPTy() {
        self.builder.createFMul(left_value, right_value)
      } else {
        self.builder.createMul(left_value, right_value)
      }
      Some(value)
    }
    Div => {
      let value = if left_value.getType().isIEEELikeFPTy() {
        self.builder.createFDiv(left_value, right_value)
      } else {
        self.builder.createSDiv(left_value, right_value)
      }
      Some(value)
    }
    Mod => {
      let value = if left_value.getType().isIEEELikeFPTy() {
        self.builder.createFRem(left_value, right_value)
      } else {
        self.builder.createSRem(left_value, right_value)
      }
      Some(value)
    }
    Eq => {
      let value = if left_value.getType().isIEEELikeFPTy() {
        self.builder.createFCmpOEQ(left_value, right_value)
      } else {
        self.builder.createICmpEQ(left_value, right_value)
      }
      Some(value)
    }
    NE => {
      let value = if left_value.getType().isIEEELikeFPTy() {
        self.builder.createFCmpONE(left_value, right_value)
      } else {
        self.builder.createICmpNE(left_value, right_value)
      }
      Some(value)
    }
    GT => {
      let value = if left_value.getType().isIEEELikeFPTy() {
        self.builder.createFCmpOGT(left_value, right_value)
      } else {
        self.builder.createICmpSGT(left_value, right_value)
      }
      Some(value)
    }
    GE => {
      let value = if left_value.getType().isIEEELikeFPTy() {
        self.builder.createFCmpOGE(left_value, right_value)
      } else {
        self.builder.createICmpSGE(left_value, right_value)
      }
      Some(value)
    }
    LT => {
      let value = if left_value.getType().isIEEELikeFPTy() {
        self.builder.createFCmpOLT(left_value, right_value)
      } else {
        self.builder.createICmpSLT(left_value, right_value)
      }
      Some(value)
    }
    LE => {
      let value = if left_value.getType().isIEEELikeFPTy() {
        self.builder.createFCmpOLE(left_value, right_value)
      } else {
        self.builder.createICmpSLE(left_value, right_value)
      }
      Some(value)
    }
    _ => raise CodegenError("Unsupported binary operation: \{op}")
  }
}
