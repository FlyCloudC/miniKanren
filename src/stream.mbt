///|
priv enum Stream[A] {
  Empty
  Cons(A, Stream[A])
  Suspension(() -> Stream[A])
}

///|
fn iter[A](self : Stream[A]) -> Iter[A] {
  Iter::new(fn(yield_) {
    loop self {
      Empty => IterContinue
      Cons(h, t) =>
        match yield_(h) {
          IterContinue => continue t
          IterEnd => IterEnd
        }
      Suspension(f) => continue f()
    }
  })
}

///|
fn mix[A](self : Stream[A], other : Stream[A]) -> Stream[A] {
  match self {
    Empty => other
    Cons(s1, s_) => Cons(s1, s_.mix(other))
    Suspension(sd) => Suspension(fn() { other.mix(sd()) })
  }
}

///|
test "mix" {
  fn int_stream_from(i) {
    Cons(i, Suspension(fn() { int_stream_from(i + 1) }))
  }

  inspect!(
    int_stream_from(100).mix(int_stream_from(200)).iter().take(10),
    content="[100, 200, 101, 201, 102, 202, 103, 203, 104, 204]",
  )
}

///|
/// s = (s1 s2 s3 ...)
/// 
/// append_map_fold_mix(s, f) = mix(f(s1), mix(f(s2), mix(f(s3), ...)))
fn map_fold_mix[A](self : Stream[A], f : (A) -> Stream[A]) -> Stream[A] {
  match self {
    Empty => Empty
    Cons(s1, s_) => f(s1).mix(s_.map_fold_mix(f))
    Suspension(sd) => Suspension(fn() { sd().map_fold_mix(f) })
  }
}

///|
test "map_fold_mix" {
  fn int_stream_from(i) {
    Cons(i, Suspension(fn() { int_stream_from(i + 1) }))
  }

  fn f(i) {
    int_stream_from(i * 100)
  }

  let a = int_stream_from(1).map_fold_mix(f)
  let a40 = a.iter().take(40).collect()
  assert_true!(a40.search(103) != None)
  assert_true!(a40.search(203) != None)
  assert_true!(a40.search(303) != None)
}
