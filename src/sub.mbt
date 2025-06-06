///| A Substitution cannot contain two or more associations with the same car.
priv type Sub @list.T[(VarId, Val)]

///|
let empty_substitution : Sub = Sub(@list.empty())

///|
fn walk(s : Sub, v : Val) -> Val {
  loop v {
    Var(x) as v =>
      match s._.lookup(x) {
        None => v
        Some(v_) => continue v_
      }
    wv => wv
  }
}

///|
fn unify(self : Sub, v1 : Val, v2 : Val) -> Sub? {
  // w for walked Val, f for freshed Var
  // if Var(x) is walked, then x is freshed

  // if wv not occur in fx, cons (fx, wv) to s
  fn ext(fx, wv) {
    fn occur_in_fx(wv) {
      match wv {
        Var(fv) => fx == fv
        Pair(l, r) => occur_in_fx(walk(self, l)) || occur_in_fx(walk(self, r))
        _ => false
      }
    }

    if occur_in_fx(wv) {
      None
    } else {
      Some(Sub(self._.add((fx, wv))))
    }
  }

  match (walk(self, v1), walk(self, v2)) {
    (wv1, wv2) if wv1 == wv2 => Some(self)
    (Var(fx), wv) | (wv, Var(fx)) => ext(fx, wv)
    (Pair(l1, r1), Pair(l2, r2)) => self.unify(l1, l2).bind(_.unify(r1, r2))
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
