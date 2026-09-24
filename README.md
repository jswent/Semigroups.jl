<h1 align="center">
<img src="docs/src/assets/logo.png" height="128" alt="Semigroups.jl">
</h1>
<p align="center">
Julia bindings for the <a href="https://libsemigroups.github.io/libsemigroups/">libsemigroups</a> C++ library.
</p>

## What is [libsemigroups][]?

Before explaining what `Semigroups.jl` is, it is first necessary to explain
[libsemigroups][]. [libsemigroups][] is a C++17 library containing
implementations of several algorithms for computing finite, and finitely
presented, semigroups and monoids. The main algorithms implemented in
[libsemigroups][] are:

- the [Froidure-Pin algorithm][] for computing semigroups and monoids defined
  by a generating set consisting of elements whose multiplication and equality
  is decidable (such as transformations, partial permutations, permutations,
  bipartitions, and matrices over a semiring);
- Kambites' algorithm for solving the word problem in small overlap monoids
  from ["Small overlap monoids I: The word problem"][], and the algorithm from
  ["An explicit algorithm for normal forms in small overlap monoids"][];
- the [Knuth-Bendix algorithm][] for finitely presented semigroups and monoids;
- a version of Sims' low index subgroup algorithm for computing congruences of a
  semigroup or monoid from
  ["Computing finite index congruences of finitely presented semigroups and monoids"][];
- a generalized version of the algorithms described in
  ["Green's equivalences in finite semigroups of binary relations"][] by
  Konieczny, and
  ["On the determination of Green's relations in finite transformation semigroups"][]
  by Lallement and Mcfadden for computing finite semigroups and monoids
  admitting a pair of actions with particular properties;
- the algorithm from
  ["Efficient Testing of Equivalence of Words in a Free Idempotent Semigroup"][]
  by Radoszewski and Rytter;
- a non-random version of the [Schreier-Sims algorithm][] for permutation groups;
- a version of Stephen's procedure from
  ["Applications of automata theory to presentations of monoids and inverse monoids"][]
  for finitely presented inverse semigroups and monoids;
- the [Todd-Coxeter algorithm][] for finitely presented semigroups and monoids;
  see also ["The Todd-Coxeter algorithm for semigroups and monoids"][].

[libsemigroups][] is partly based on
[Algorithms for computing finite semigroups][Froidure-Pin algorithm],
[Expository Slides][], and [Semigroupe 2.01][] by [Jean-Eric Pin][].

[Froidure-Pin algorithm]: https://www.irif.fr/~jep/PDF/Rio.pdf
["Small overlap monoids I: The word problem"]: https://doi.org/10.1016/j.jalgebra.2008.09.038
["An explicit algorithm for normal forms in small overlap monoids"]: https://doi.org/10.1016/j.jalgebra.2023.04.019
[Knuth-Bendix algorithm]: https://en.wikipedia.org/wiki/Knuth%E2%80%93Bendix_completion_algorithm
["Computing finite index congruences of finitely presented semigroups and monoids"]: https://arxiv.org/abs/2302.06295
["Green's equivalences in finite semigroups of binary relations"]: https://link.springer.com/article/10.1007/BF02573672
["On the determination of Green's relations in finite transformation semigroups"]: https://www.sciencedirect.com/science/article/pii/S0747717108800570
["Efficient Testing of Equivalence of Words in a Free Idempotent Semigroup"]: https://link.springer.com/chapter/10.1007/978-3-642-11266-9_55
["Applications of automata theory to presentations of monoids and inverse monoids"]: https://digitalcommons.unl.edu/dissertations/AAI8803771/
[Todd-Coxeter algorithm]: https://en.wikipedia.org/wiki/Todd%E2%80%93Coxeter_algorithm
["The Todd-Coxeter algorithm for semigroups and monoids"]: https://doi.org/10.1007/s00233-024-10431-z
[Schreier-Sims algorithm]: https://en.wikipedia.org/wiki/Schreier%E2%80%93Sims_algorithm
[Expository Slides]: https://www.irif.fr/~jep/PDF/Exposes/StAndrews.pdf
[Semigroupe 2.01]: https://www.irif.fr/~jep/Logiciels/Semigroupe2.0/semigroupe2.html
[Jean-Eric Pin]: https://www.irif.fr/~jep/

## What is `Semigroups.jl`?

`Semigroups.jl` is a package for Julia 1.10+ exposing much (but not all) of
the functionality of [libsemigroups][]. It is built with the help of the
excellent library [CxxWrap.jl][], for which we are very grateful.

The development version of `Semigroups.jl` is available on
[GitHub](https://github.com/libsemigroups/Semigroups.jl), and some related
projects are [here](https://github.com/libsemigroups).

[libsemigroups]: https://libsemigroups.github.io/libsemigroups/
[CxxWrap.jl]: https://github.com/JuliaInterop/CxxWrap.jl

## How to install `Semigroups.jl`

To install `Semigroups.jl` from GitHub:

```julia
using Pkg
Pkg.add("Semigroups")
using Semigroups
```

For more detailed installation instructions, including prerequisites and
troubleshooting, see the
[documentation](https://libsemigroups.github.io/Semigroups.jl/).

## Issues

If you find any problems with `Semigroups.jl`, or have any suggestions for
features that you'd like to see, please use the
[issue tracker](https://github.com/libsemigroups/Semigroups.jl/issues).

## Acknowledgements

In addition to [libsemigroups][], there are several excellent projects that
are utilised in the development of `Semigroups.jl`, specifically:

- [CxxWrap.jl][] for Julia-C++ interop;
- [Documenter.jl][] for the documentation.

We would like to thank the authors and contributors of these projects!

[Documenter.jl]: https://documenter.juliadocs.org/

## Development

A Makefile is provided for common development tasks:

| Command           | Description                  |
| ----------------- | ---------------------------- |
| `make test`       | Run the test suite           |
| `make docs`       | Build documentation          |
| `make docs-serve` | Build and serve docs locally |
| `make build`      | Build C++ bindings           |
| `make clean`      | Clean build artifacts        |
| `make format`     | Format Julia and C++ code    |
