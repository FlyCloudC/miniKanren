///|
/// A Substitution cannot contain two or more associations with the same car.
priv struct Sub(@immut_hashmap.HashMap[VarId, Val])

///|
let empty_substitution : Sub = Sub(@immut_hashmap.new())

///|
fn walk(s : Sub, v : Val) -> Val {
  loop v {
    Var(x) as v =>
      match s.0.get(x) {
        None => v
        Some(v_) => continue v_
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
    fn occur_in_fx(wv) {
      match wv {
        Var(fv) => fx == fv
        Pair(l, r) => occur_in_fx(walk(s, l)) || occur_in_fx(walk(s, r))
        _ => false
      }
    }

    if occur_in_fx(wv) {
      None
    } else {
      Some(Sub(s.0.add(fx, wv)))
    }
  }

  match (walk(s, v1), walk(s, v2)) {
    (wv1, wv2) if wv1 == wv2 => Some(s)
    (Var(fx), wv) | (wv, Var(fx)) => ext(fx, wv)
    (Pair(l1, r1), Pair(l2, r2)) => s.unify(l1, l2).bind(s => s.unify(r1, r2))
    _ => None
  }
}

///|
fn reify(s : Sub, v : Val) -> Val {
  let map = @hashmap.new()
  let next_var = new_fresh_var_generator()
  fn replace(v) {
    match walk(s, v) {
      Var(x) => map.get_or_init(x, next_var)
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
