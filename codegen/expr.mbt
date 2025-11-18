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
      guard value is Some(value) else {
        raise CodegenError("Identifier not found in name_values: \{name}")
      }
      println("name: \{name}, value: \{value}")
      if value.asValueEnum() is AllocaInst(ptr) {
        let value = self.builder.createLoad(ptr.data_ty, ptr)
        println("load value: \{value}")
        Some(value)
      } else {
        Some(value)
      }
    }
    Not(name) => {
      let value = self.expr_codegen(Ident(name))
      guard value is Some(value) else {
        raise CodegenError("expr_codegen returned None")
      }
      Some(self.builder.createXor(self.llvm_ctx.getConstTrue(), value))
    }
    Neg(name) => {
      let value = self.expr_codegen(Ident(name))
      guard value is Some(value) else {
        raise CodegenError("expr_codegen returned None")
      }
      if value.getType().isIEEELikeFPTy() {
        Some(self.builder.createFNeg(value))
      } else {
        Some(self.builder.createSub(self.llvm_ctx.getConstInt32(0), value))
      }
    }
    Binary(op, left, right) => {
      let left_value = self.expr_codegen(Ident(left))
      guard left_value is Some(left_value) else {
        raise CodegenError("expr_codegen returned None")
      }
      let right_value = self.expr_codegen(Ident(right))
      guard right_value is Some(right_value) else {
        raise CodegenError("expr_codegen returned None")
      }
      match op {
        Add => {
          let value = if left_value.getType().isIEEELikeFPTy() {
            self.builder.createFAdd(left_value, right_value)
          } else {
            self.builder.createAdd(left_value, right_value)
          }
          Some(value)
        }
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
    ArrayMake(size_name, init_name) => {
      let init_ty = self.name_types.get(init_name)
      guard init_ty is Some(init_ty) else {
        raise CodegenError("init_name not found: \{init_name}")
      }
      let make_func = match init_ty {
        Int => self.builtin_funcs.get("make_int_array").unwrap()
        Double => self.builtin_funcs.get("make")
      }

    }
    e => raise CodegenError("Unsupported expression in codegen: \{e}")
  }
}
