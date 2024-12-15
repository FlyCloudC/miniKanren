///|
pub fn nilo(v : Val) -> Goal {
  eqo(v, Nil)
}

///|
pub fn conso(a : Val, d : Val, p : Val) -> Goal {
  eqo(Pair(a, d), p)
}

///|
pub fn caro(p : Val, a : Val) -> Goal {
  eqo(p, Pair(a, fresh_var()))
}

///|
pub fn cdro(p : Val, d : Val) -> Goal {
  eqo(p, Pair(fresh_var(), d))
}

///|
pub fn listo(v : Val) -> Goal {
  nilo(v) |
  delay(
    fn() {
      let d = fresh_var()
      cdro(v, d) & listo(d)
    },
  )
}

test "listo" {
  inspect!(
    run_and_display(n=4, fn { v => listo(v) }),
    content=
      #|()
      #|(_₀)
      #|(_₀ _₁)
      #|(_₀ _₁ _₂)
    ,
  )
}

///|
pub fn membero(e : Val, ls : Val) -> Goal {
  caro(ls, e) |
  delay(
    fn() {
      let d = fresh_var()
      cdro(ls, d) & membero(e, d)
    },
  )
}

///|
test "membero" {
  inspect!(
    run_and_display(
      n=10,
      fn {
        v =>
          listo(v) & //
          membero(Int(1), v) &
          membero(Int(0), v)
      },
    ),
    content=
      #|(1 0)
      #|(0 1)
      #|(1 0 _₀)
      #|(1 _₀ 0)
      #|(0 1 _₀)
      #|(_₀ 1 0)
      #|(1 0 _₀ _₁)
      #|(0 _₀ 1)
      #|(1 _₀ 0 _₁)
      #|(1 _₀ _₁ 0)
    ,
  )
}

///|
pub fn appendo(l1 : Val, l2 : Val, o : Val) -> Goal {
  (nilo(l1) & eqo(l2, o)) |
  delay(
    fn() {
      let l1a = fresh_var()
      let l1d = fresh_var()
      let od = fresh_var()
      conso(l1a, od, o) & //
      appendo(l1d, l2, od) &
      conso(l1a, l1d, l1)
    },
  )
}

///| return (1 2 ... n)
fn int_list(n : Int) -> Val {
  n.until(0, step=-1).fold(init=Nil, fn { r, l => Pair(Int(l), r) })
}

test "appendo" {
  inspect!(
    run_and_display(
      fn {
        v => {
          let (l1, l2, l3) = fresh_var_3()
          let l12 = fresh_var()
          appendo(l12, l3, int_list(3)) & //
          appendo(l1, l2, l12) &
          eqo(v, list([l1, l2, l3]))
        }
      },
    ),
    content=
      #|(() () (1 2 3))
      #|(() (1) (2 3))
      #|((1) () (2 3))
      #|(() (1 2) (3))
      #|((1) (2) (3))
      #|(() (1 2 3) ())
      #|((1 2) () (3))
      #|((1) (2 3) ())
      #|((1 2) (3) ())
      #|((1 2 3) () ())
    ,
  )
}
