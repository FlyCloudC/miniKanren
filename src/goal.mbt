///|
/// A `Goal` is a function that takes a substitution and returns a stream of 
/// substitutions that satisfy the goal.
struct Goal((Sub) -> Stream[Sub])

///|
/// Creates a goal that unifies two values in a logic programming context. The
/// goal succeeds if the two values can be unified under some substitution,
/// producing a stream containing the unified substitution. If unification fails,
/// produces an empty stream.
///
/// Parameters:
///
/// * `first` : First logic value to be unified.
/// * `second` : Second logic value to be unified.
///
/// Returns a `Goal` that, when executed with a substitution, attempts to unify
/// the two values under that substitution.
///
/// Example:
///
/// ```moonbit nocheck
/// inspect(run1(x => eqo(x, Int(42))), content="42")
/// ```
pub fn eqo(u : Val, v : Val) -> Goal {
  Goal(s => {
    match s.unify(u, v) {
      None => Empty
      Some(s_) => Cons(s_, Empty)
    }
  })
}

///|
pub impl BitOr for Goal with fn lor(g1, g2) {
  Goal(s => g1(s).mix(g2(s)))
}

///|
pub impl BitAnd for Goal with fn land(g1, g2) {
  Goal(s => g1(s).map_fold_mix(g2.0))
}

///|
/// Creates a lazy goal that delays the evaluation of its body until it is
/// needed.
///
/// Parameters:
///
/// * `goal_fn` : A function that takes no arguments and returns a goal. This
/// function will be evaluated lazily when the resulting goal is applied to a
/// substitution.
///
/// Returns a new goal that, when applied to a substitution, creates a suspension
/// that will evaluate the original goal function only when forced.
///
/// Example:
///
/// ```moonbit nocheck
/// fn manyo(g : Goal) -> Goal {
///   g | delay(() => manyo(g))
/// }
///
/// inspect(run1(x => manyo(eqo(x, Int(1)))), content="1")
/// ```
pub fn delay(goal_fn : () -> Goal) -> Goal {
  Goal(s => Suspension(() => goal_fn()(s)))
}

///|
/// Executes a query and returns an iterator of solutions.
///
/// Parameters:
///
/// * `query` : A function that takes a logic variable and returns a goal. This
/// function defines the logic query to be executed.
///
/// Returns an iterator that produces the solutions to the query. Each solution
/// is a concrete value that satisfies the constraints defined in the query.
///
/// Example:
///
/// ```moonbit nocheck
/// inspect(run(x => eqo(x, Int(42))), content="[42]")
/// ```
pub fn run(query : (Val) -> Goal) -> Iter[Val] {
  let query_var = fresh_var()
  let subs = query(query_var)(empty_substitution)
  subs.iter().map(s => reify(s, query_var))
}

///|
/// Returns the first solution of a logic query.
///
/// Parameters:
///
/// * `query` : A function that takes a logic variable and returns a goal. This
/// function defines the logic query to be executed. This query should have at
/// least one solution, otherwise the function will panic.
///
/// Returns the first concrete value that satisfies the constraints defined in
/// the query.
///
/// Example:
///
/// ```moonbit nocheck
/// inspect(run1(x => eqo(x, Int(42))), content="42")
/// ```
#internal(unsafe, "Panic if there is no solution.")
pub fn run1(query : (Val) -> Goal) -> Val {
  run(query).next().unwrap()
}

///|
fn run_and_display(f : (Val) -> Goal, n? : Int) -> String {
  let vals = run(f)
  (match n {
    Some(n) => vals.take(n)
    None => vals
  })
  .map(Show::to_string)
  .join("\n")
}

///|
test "or" {
  inspect(
    run_and_display(v => eqo(v, Int(1)) | eqo(v, Int(2))),
    content=(
      #|1
      #|2
    ),
  )
}

///|
test "and" {
  inspect(
    run_and_display(v => {
      let t = fresh_var()
      eqo(t, Int(1)) & //
      eqo(v, t)
    }),
    content="1",
  )
  assert_eq(run(v => eqo(v, Int(1)) & eqo(v, Int(2))).count(), 0)
}

///|
test "delay" {
  fn manyo(g) {
    g | delay(() => manyo(g))
  }

  inspect(
    run_and_display(n=5, v => manyo(eqo(v, Int(1)))),
    content=(
      #|1
      #|1
      #|1
      #|1
      #|1
    ),
  )
}
