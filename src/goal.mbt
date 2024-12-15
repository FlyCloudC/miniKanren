///|
type Goal (Sub) -> Stream[Sub]

///|
pub fn eqo(u : Val, v : Val) -> Goal {
  Goal(
    fn(s) {
      match s.unify(u, v) {
        None => Empty
        Some(s_) => Cons(s_, Empty)
      }
    },
  )
}

///|
pub fn Goal::lor(g1 : Goal, g2 : Goal) -> Goal {
  Goal(fn { s => mix((g1._)(s), (g2._)(s)) })
}

///|
pub fn Goal::land(g1 : Goal, g2 : Goal) -> Goal {
  Goal(fn { s => (g1._)(s).append_map_fold_mix(g2._) })
}

///|
pub fn delay(f : () -> Goal) -> Goal {
  Goal(fn(s) { Suspension(fn() { (f()._)(s) }) })
}

///|
pub fn run(f : (Val) -> Goal) -> Iter[Val] {
  let qv = fresh_var()
  let g = f(qv)
  (g._)(empty_substitution).iter().map(reify(qv))
}

///|
fn run_and_display(f : (Val) -> Goal, n? : Int) -> String {
  let s = run(f)
  (match n {
    Some(n) => s.take(n)
    None => s
  })
  .map(Val::to_string)
  .to_array()
  |> String::concat(separator="\n")
}

test "or" {
  inspect!(
    run_and_display(
      fn {
        v =>
          eqo(v, Int(1)) | //
          eqo(v, Int(2))
      },
    ),
    content=
      #|1
      #|2
    ,
  )
}

test "and" {
  inspect!(
    run_and_display(
      fn {
        v => {
          let t = fresh_var()
          eqo(t, Int(1)) & //
          eqo(v, t)
        }
      },
    ),
    content="1",
  )
}

test "delay" {
  fn manyo {
    g => g | delay(fn() { manyo(g) })
  }

  inspect!(
    run_and_display(
      n=5,
      fn {
        v => //
          manyo(eqo(v, Int(1)))
      },
    ),
    content=
      #|1
      #|1
      #|1
      #|1
      #|1
    ,
  )
}
