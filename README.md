# FlyFloudC/miniKanren

The logic programming language, miniKanren.

More information: 

* Daniel P. Friedman, William E. Byrd, Oleg Kiselyov, and Jason Hemann - [The Reasoned Schemer](https://mitpress.mit.edu/books/reasoned-schemer-second-edition)
* [miniKanren.org](https://minikanren.org/)

## Example

```moonbit
// find all lists whose 1 and 0 are both in it
let solutions : Iter[Val] = run(fn {
  v =>
    listo(v) & //
    membero(Int(1), v) &
    membero(Int(0), v)
})

solutions.take(10).each(println)
```

The output is

```scheme
(1 0)
(0 1)
(1 0 _₀)
(1 _₀ 0)
(0 1 _₀)
(_₀ 1 0)
(1 0 _₀ _₁)
(0 _₀ 1)
(1 _₀ 0 _₁)
(1 _₀ _₁ 0)
```
