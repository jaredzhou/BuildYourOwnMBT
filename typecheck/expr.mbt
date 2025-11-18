///|
pub(all) struct Expr {
  kind : ExprKind
  ty : TypeKind
} derive(Show)

///|
pub(all) enum ExprKind {
  ApplyExpr(ApplyExpr)
  BlockExpr(BlockExpr)
  NotExpr(Expr)
  NegExpr(Expr)
  BinaryExpr(BinaryOp, Expr, Expr)
  IfExpr(IfExpr)
} derive(Show)

///|
pub(all) enum BinaryOp {
  Add // +
  Sub // -
  Mul // *
  Div // /
  Mod // %
  ShiftLeft // <<
  ShiftRight // >>
  Eq // ==
  NE // !=
  LT // <
  GT // >
  LE // <=
  GE // >=
  And // &&
  Or // ||
  BitAnd // &
  BitOr // |
} derive(Show, Eq)

///|
pub fn binop_is_cmp(bin_op : BinaryOp) -> Bool {
  match bin_op {
    Eq => true
    NE => true
    LT => true
    GT => true
    LE => true
    GE => true
    _ => false
  }
}

///|
pub fn binop_is_bitwise(bin_op : BinaryOp) -> Bool {
  bin_op is (BitAnd | BitOr)
}

///|
pub fn binop_is_arithmetic(bin_op : BinaryOp) -> Bool {
  match bin_op {
    Add => true
    Sub => true
    Mul => true
    Div => true
    Mod => true
    _ => false
  }
}

///|
pub fn binop_is_logical(bin_op : BinaryOp) -> Bool {
  match bin_op {
    And => true
    Or => true
    _ => false
  }
}

///|
pub fn parser_binop_to_typecheck_binop(
  tok_bin_op : @parser.BinaryOp,
) -> BinaryOp {
  match tok_bin_op {
    Add => Add
    Sub => Sub
    Mul => Mul
    Div => Div
    Mod => Mod
    ShiftLeft => ShiftLeft
    ShiftRight => ShiftRight
    Eq => Eq
    NE => NE
    LT => LT
    GT => GT
    LE => LE
    GE => GE
    And => And
    Or => Or
    BitAnd => BitAnd
    BitOr => BitOr
  }
}

///|
pub fn Context::check_expr(
  self : Self,
  expr : @parser.Expr,
) -> Expr raise TypeCheckError {
  match expr.kind {
    ApplyExpr(apply_expr) => {
      let apply_expr = self.check_apply_expr(apply_expr)
      Expr::{ kind: ApplyExpr(apply_expr), ty: apply_expr.ty }
    }
    NotExpr(inner_expr) => {
      let inner_expr = self.check_expr(inner_expr)
      guard inner_expr.ty is TypeKind::Bool else {
        raise TypeCheckError("not_expr: inner_expr must be a bool")
      }
      Expr::{ kind: NotExpr(inner_expr), ty: TypeKind::Bool }
    }
    NegExpr(inner_expr) => {
      let inner_expr = self.check_expr(inner_expr)
      guard inner_expr.ty is (TypeKind::Int | TypeKind::Double) else {
        raise TypeCheckError("neg_expr: inner_expr must be an int or double")
      }
      Expr::{ kind: NegExpr(inner_expr), ty: inner_expr.ty }
    }
    BinaryExpr(op, left, right) => {
      let op = parser_binop_to_typecheck_binop(op)
      let left = self.check_expr(left)
      let right = self.check_expr(right)
      guard self.is_type_compatible(left.ty, right.ty) else {
        raise TypeCheckError(
          "binary_expr: left and right must be the same type: '\{expr}'",
        )
      }
      match op {
        op if binop_is_arithmetic(op) => {
          guard left.ty is (Int | Double | TypeVar(_)) else {
            raise TypeCheckError(
              "binary_expr: arith expr left and right must be Int or Double '\{expr}'",
            )
          }
          Expr::{ kind: BinaryExpr(op, left, right), ty: left.ty }
        }
        op if binop_is_cmp(op) => {
          guard left.ty is (Int | Double | Bool | TypeVar(_)) else {
            raise TypeCheckError(
              "binary_expr: comp expr left and right must be Int or Double '\{expr}'",
            )
          }
          Expr::{ kind: BinaryExpr(op, left, right), ty: Bool }
        }
        op if binop_is_logical(op) => {
          guard left.ty is Bool else {
            raise TypeCheckError(
              "binary_expr: logical expr left and right must be Bool",
            )
          }
          Expr::{ kind: BinaryExpr(op, left, right), ty: Bool }
        }
        op if binop_is_bitwise(op) => {
          guard left.ty is Int else {
            raise TypeCheckError(
              "binary_expr: bitwise expr left and right must be Int ",
            )
          }
          Expr::{ kind: BinaryExpr(op, left, right), ty: Int }
        }
        _ =>
          raise TypeCheckError("binary_expr: invalid binary operator: '{op}'")
      }
    }
    IfExpr(if_expr) => {
      let if_expr = self.check_if_expr(if_expr)
      Expr::{ kind: IfExpr(if_expr), ty: if_expr.ty }
    }
    other =>
      raise TypeCheckError("expr '\{other}': type not implemented or invalid")
  }
}
