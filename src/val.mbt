///|
/// Represents a unique identifier for logic variables.
struct VarId(Int) derive(Eq)

///|
pub impl Hash for VarId with fn hash_combine(self, hasher) {
  hasher.combine_int(self.0)
}

///|
pub impl Hash for VarId with fn hash(self) {
  self.0
}

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
/// ```moonbit nocheck
/// assert_eq(
///   list_from_array([Int(1), Int(2), Int(3)]),
///   Pair(Int(1), Pair(Int(2), Pair(Int(3), Nil))),
/// )
/// ```
pub fn list_from_array(vs : Array[Val]) -> Val {
  vs.rev_fold(init=Nil, (acc, v) => Pair(v, acc))
}

///|
fn new_fresh_var_generator() -> () -> Val {
  let mut i = -1
  () => {
    i += 1
    Var(i)
  }
}

///|
/// Creates a new, unique logic variable. Each call to this function returns a
/// different variable.
pub let fresh_var : () -> Val = new_fresh_var_generator()

///|
/// Creates 2 new, unique logic variables.
pub fn fresh_var_2() -> (Val, Val) {
  (fresh_var(), fresh_var())
}

///|
/// Creates 3 new, unique logic variables.
pub fn fresh_var_3() -> (Val, Val, Val) {
  (fresh_var(), fresh_var(), fresh_var())
}

///|
pub impl Show for Val with fn output(self, logger) {
  match self {
    Int(i) => logger <+ "\{i}"
    Var(x) => logger <+ "\{x}"
    Nil => logger <+ "()"
    Pair(l, r) => {
      logger <+ "(\{l}"
      for r = r; r is Pair(l, r); {
        logger <+ " \{l}"
        continue r
      } nobreak {
        match r {
          Nil => logger.write_char(')')
          v => logger <+ " . \{v})"
        }
      }
    }
  }
}

///|
const SUBSCRIPT_0 : Int = '₀'

///|
pub impl Show for VarId with fn output(self, logger) {
  guard self.0 > 0 else { logger <+ "_₀" }
  let digits = [
    for n = self.0; n > 0; n = n / 10 => (SUBSCRIPT_0 + n % 10).unsafe_to_char()
  ]
  logger.write_char('_')
  digits.rev_each(d => logger.write_char(d))
}
