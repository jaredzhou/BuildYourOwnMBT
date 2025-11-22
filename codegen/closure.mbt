///|
pub fn Context::closure_codegen(
  self : Context,
  closure_def : @knf.KnfClosure,
) -> Unit raise {
  let ptrty = self.llvm_ctx.getPtrTy()
  let { name, params, ret_ty, body, captured_vars } = closure_def
  println(
    "closure_codegen name: \{name} params: \{params} ret_ty: \{ret_ty} body: \{body} captured_vars: \{captured_vars}",
  )
  let param_types : Array[&@llvm.Type] = [ptrty]
  params.each(param => {
    let llvm_param_type = self.type_codegen_opaque(param.1)
    param_types.push(llvm_param_type)
  })
  let llvm_ret_type = self.type_codegen_opaque(ret_ty)
  println("creating function \{name.id} with ret_type: \{llvm_ret_type}")
  let llvm_fty = self.llvm_ctx.getFunctionType(llvm_ret_type, param_types)
  let llvm_func = self.llvm_mod.addFunction(llvm_fty, name.id)
  println(
    "added function \{name.id}, return type: \{llvm_func.getReturnType()}",
  )
  self.functions.set(name.id, llvm_func)
  let entry_block = llvm_func.addBasicBlock(name="entry")
  self.builder.setInsertPoint(entry_block)
  //预留了一个arg， 所以从第二个arg开始
  params.eachi((i, param) => {
    let arg = llvm_func.getArg(i + 1).unwrap()
    println("set param \{param.0} with value: \{arg} type: \{param.1}")
    self.name_values.set(param.0, arg)
    self.name_types.set(param.0, param.1)
  })
  match body.stmts.length() {
    0 => {
      match ret_ty {
        Unit => {
          let _ = self.builder.createRetVoid()

        }
        _ => {
          let default_value = self.get_default_value(ret_ty)
          let _ = self.builder.createRet(default_value)

        }
      }
      self.name_values.set(name, llvm_func)
      self.name_types.set(name, Function(params.map(param => param.1), ret_ty))
      return
    }
    n => {
      body.stmts[:n - 1].each(stmt => self.stmt_codegen(stmt))
      let last_stmt = body.stmts[n - 1]
      match last_stmt {
        ExprStmt(expr) => {
          let value = self.expr_codegen(expr)
          println("closure expr_codegen expr: \{expr} value: \{value}")
          match value {
            Some(value) => {
              let current_func = self.builder.getInsertFunction()
              println(
                "closure codegen creating ret with value: \{value}, type: \{value.getType()}",
              )
              let _ = self.builder.createRet(value)

            }
            None =>
              match ret_ty {
                Unit => {
                  let _ = self.builder.createRetVoid()

                }
                _ =>
                  raise CodegenError(
                    "closure expr returned None but ret_ty is not Unit: \{ret_ty}",
                  )
              }
          }
        }
        Return(_) | ReturnUnit => self.stmt_codegen(last_stmt)
        _ => {
          self.stmt_codegen(last_stmt)
          match ret_ty {
            Unit => {
              let _ = self.builder.createRetVoid()

            }
            _ => {
              let default_value = self.get_default_value(ret_ty)
              let _ = self.builder.createRet(default_value)

            }
          }
        }
      }
    }
  }
  self.name_values.set(name, llvm_func)
  self.name_types.set(name, Function(params.map(param => param.1), ret_ty))
}
