///| A Substitution cannot contain two or more associations with the same car.
type Sub @immut/list.T[(VarId, Val)]

///|
let empty_substitution : Sub = Sub(Nil)

///|
fn walk(s : Sub, v : Val) -> Val {
  match v {
    Var(x) =>
      match s._.lookup(x) {
        None => v
        Some(v_) => walk(s, v_)
      }
    wv => wv
  }
}

///|
fn Sub::unify(s : Sub, v1 : Val, v2 : Val) -> Sub? {
  // w for walked Val, f for freshed Var
  // if Var(x) is walked, then x is freshed

  // if wv not occur in fx, cons (fx, wv) to s
  fn ext(fx, wv) {
    fn fx_occur {
      Var(fv) => fx == fv
      Pair(l, r) => fx_occur(walk(s, l)) || fx_occur(walk(s, r))
      _ => false
    }

    if fx_occur(wv) {
      None
    } else {
      Some(Sub(Cons((fx, wv), s._)))
    }
  }

  let wv1 = walk(s, v1)
  let wv2 = walk(s, v2)
  if wv1 == wv2 {
    Some(s)
  } else {
    match (wv1, wv2) {
      (Var(fx), wv) | (wv, Var(fx)) => ext(fx, wv)
      (Pair(l1, r1), Pair(l2, r2)) =>
        s.unify(l1, l2).bind(fn { s_ => s_.unify(r1, r2) })
      _ => None
    }
  }
}

///|
fn reify(v : Val) -> (Sub) -> Val {
  fn(s) {
    let map = @hashmap.new()
    let next_var = new_fresh_var_generator()
    fn replace_fresh_var(id) {
      match map[id] {
        Some(v_) => v_
        None => {
          let v_ = next_var()
          map[id] = v_
          v_
        }
      }
    }

    fn replace(v) {
      match walk(s, v) {
        Var(VarId(id)) => replace_fresh_var(id)
        Pair(l, r) => {
          let lv = replace(l)
          let rv = replace(r)
          Pair(lv, rv)
        }
        wv => wv
      }
    }

    replace(v)
  }
}
