///|
enum Stream[A] {
  Empty
  Cons(A, Stream[A])
  Suspension(() -> Stream[A])
}

///|
fn Stream::iter[A](s : Stream[A]) -> Iter[A] {
  Iter::new(
    fn(yield_) {
      loop s {
        Empty => IterContinue
        Cons(h, t) =>
          match yield_(h) {
            IterContinue => continue t
            IterEnd => IterEnd
          }
        Suspension(f) => continue f()
      }
    },
  )
}

///| 
/// s1 = (s11 s12 s13 ...)
/// 
/// s2 = (s21 s22 s23 ...)
/// 
/// mix(s1, s2) = (s11 s21 s12 s22 s13 s23 ...)
fn Stream::mix[A](s1 : Stream[A], s2 : Stream[A]) -> Stream[A] {
  match s1 {
    Empty => s2
    Cons(s11, s1_) => Cons(s11, mix(s1_, s2))
    Suspension(sd) => Suspension(fn() { mix(s2, sd()) })
  }
}

///|
/// s = (s1 s2 s3 ...)
/// 
/// append_map_fold_mix(s, f) = mix(f(s1), mix(f(s2), mix(f(s3), ...)))
fn Stream::append_map_fold_mix[A](
  s : Stream[A],
  f : (A) -> Stream[A]
) -> Stream[A] {
  match s {
    Empty => Empty
    Cons(s1, s_) => f(s1).mix(s_.append_map_fold_mix(f))
    Suspension(sd) => Suspension(fn() { sd().append_map_fold_mix(f) })
  }
}
