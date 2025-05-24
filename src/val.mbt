///|
/// Represents a unique identifier for logic variables.
type VarId Int derive(Eq, Hash)

///|
pub(all) enum Val {
  Int(Int)
  Nil
  Pair(Val, Val)
  Var(VarId)
} derive(Eq)

///|
/// Creates a list from an array of values. The resulting list is represented
/// as nested pairs terminated by `Nil`.
///
/// Example:
///
/// ```moonbit
/// ///|
/// test "list_from_array" {
///   assert_eq(
///     list_from_array([Int(1), Int(2), Int(3)]),
///     Pair(Int(1), Pair(Int(2), Pair(Int(3), Nil))),
///   )
/// }
/// ```
pub fn list_from_array(vs : Array[Val]) -> Val {
  vs.rev_fold(init=Nil, fn { acc, v => Pair(v, acc) })
}

///|
fn new_fresh_var_generator() -> () -> Val {
  let mut i = -1
  fn() {
    i += 1
    Var(i)
  }
}

///|
/// Creates a new, unique logic variable. Each call to this function returns a
/// different variable.
pub let fresh_var : () -> Val = new_fresh_var_generator()

///| Creates 2 new, unique logic variables.
pub fn fresh_var_2() -> (Val, Val) {
  (fresh_var(), fresh_var())
}

///| Creates 3 new, unique logic variables.
pub fn fresh_var_3() -> (Val, Val, Val) {
  (fresh_var(), fresh_var(), fresh_var())
}

///|
fn to_subscript(n : Int) -> String {
  if n == 0 {
    "_₀"
  } else {
    let b = StringBuilder::new()
    loop n {
      0 => b..write_char('_').to_string().rev()
      n => {
        let sub_0 = '₀'.to_int()
        b.write_char(Int::unsafe_to_char(sub_0 + n % 10))
        continue n / 10
      }
    }
  }
}

///|
pub impl Show for Val with output(self, logger) {
  match self {
    Int(i) => i.output(logger)
    Var(VarId(x)) => logger.write_string(to_subscript(x))
    Nil => logger.write_string("()")
    Pair(l, r) => {
      logger..write_char('(')..write_object(l)
      loop r {
        Nil => logger.write_char(')')
        Pair(l, r) => {
          logger..write_char(' ')..write_object(l)
          continue r
        }
        v => logger..write_string(" . ")..write_object(v)..write_char(')')
      }
    }
  }
}
