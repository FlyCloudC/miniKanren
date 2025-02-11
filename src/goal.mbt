///|
type Goal (Sub) -> Stream[Sub]

///|
fn apply(self : Goal, s : Sub) -> Stream[Sub] {
  (self._)(s)
}

///|
pub fn eqo(u : Val, v : Val) -> Goal {
  Goal(fn(s) {
    match s.unify(u, v) {
      None => Empty
      Some(s_) => Cons(s_, Empty)
    }
  })
}

///|
pub fn Goal::lor(g1 : Goal, g2 : Goal) -> Goal {
  Goal(fn { s => g1.apply(s).mix(g2.apply(s)) })
}

///|
pub fn Goal::land(g1 : Goal, g2 : Goal) -> Goal {
  Goal(fn { s => g1.apply(s).map_fold_mix(g2._) })
}

///|
pub fn delay(f : () -> Goal) -> Goal {
  Goal(fn(s) { Suspension(fn() { f().apply(s) }) })
}

///|
pub fn run(f : (Val) -> Goal) -> Iter[Val] {
  let qv = fresh_var()
  let subs = f(qv).apply(empty_substitution)
  subs.iter().map(fn { s => reify(s, qv) })
}

///|
fn run_and_display(f : (Val) -> Goal, n? : Int) -> String {
  let vals = run(f)
  (match n {
    Some(n) => vals.take(n)
    None => vals
  })
  .map(Val::to_string)
  .to_array()
  |> String::concat(separator="\n")
}

///|
test "or" {
  inspect!(
    run_and_display(fn {
      v =>
        eqo(v, Int(1)) | //
        eqo(v, Int(2))
    }),
    content=
      #|1
      #|2
    ,
  )
}

///|
test "and" {
  inspect!(
    run_and_display(fn {
      v => {
        let t = fresh_var()
        eqo(t, Int(1)) & //
        eqo(v, t)
      }
    }),
    content="1",
  )
}

///|
test "delay" {
  fn manyo {
    g => g | delay(fn() { manyo(g) })
  }

  inspect!(
    run_and_display(n=5, fn {
      v => manyo(eqo(v, Int(1))) //
    }),
    content=
      #|1
      #|1
      #|1
      #|1
      #|1
    ,
  )
}
