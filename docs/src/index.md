# Semigroups.jl

## What is [libsemigroups](https://libsemigroups.github.io/libsemigroups/)?

Before explaining what `Semigroups.jl` is, it is first necessary to explain
[libsemigroups](https://libsemigroups.github.io/libsemigroups/).
[libsemigroups](https://libsemigroups.github.io/libsemigroups/) is a C++17
library containing implementations of several algorithms for computing finite,
and finitely presented, semigroups and monoids. The main algorithms implemented
in [libsemigroups](https://libsemigroups.github.io/libsemigroups/) are:

- the [Froidure-Pin algorithm](https://www.irif.fr/~jep/PDF/Rio.pdf) for
  computing semigroups and monoids defined by a generating set consisting of
  elements whose multiplication and equality is decidable (such as
  transformations, partial permutations, permutations, bipartitions, and
  matrices over a semiring);
- Kambites' algorithm for solving the word problem in small overlap monoids
  from [Small overlap monoids I: The word problem](https://doi.org/10.1016/j.jalgebra.2008.09.038),
  and the algorithm from
  [An explicit algorithm for normal forms in small overlap monoids](https://doi.org/10.1016/j.jalgebra.2023.04.019);
- the [Knuth-Bendix algorithm](https://en.wikipedia.org/wiki/Knuth%E2%80%93Bendix_completion_algorithm)
  for finitely presented semigroups and monoids;
- a version of Sims' low index subgroup algorithm for computing congruences of a
  semigroup or monoid from
  [Computing finite index congruences of finitely presented semigroups and monoids](https://arxiv.org/abs/2302.06295);
- a generalized version of the algorithms described in
  [Green's equivalences in finite semigroups of binary relations](https://link.springer.com/article/10.1007/BF02573672)
  by Konieczny, and
  [On the determination of Green's relations in finite transformation semigroups](https://www.sciencedirect.com/science/article/pii/S0747717108800570)
  by Lallement and Mcfadden for computing finite semigroups and monoids
  admitting a pair of actions with particular properties;
- the algorithm from
  [Efficient Testing of Equivalence of Words in a Free Idempotent Semigroup](https://link.springer.com/chapter/10.1007/978-3-642-11266-9_55)
  by Radoszewski and Rytter;
- a non-random version of the
  [Schreier-Sims algorithm](https://en.wikipedia.org/wiki/Schreier%E2%80%93Sims_algorithm)
  for permutation groups;
- a version of Stephen's procedure from
  [Applications of automata theory to presentations of monoids and inverse monoids](https://digitalcommons.unl.edu/dissertations/AAI8803771/)
  for finitely presented inverse semigroups and monoids;
- the [Todd-Coxeter algorithm](https://en.wikipedia.org/wiki/Todd%E2%80%93Coxeter_algorithm)
  for finitely presented semigroups and monoids; see also
  [The Todd-Coxeter algorithm for semigroups and monoids](https://doi.org/10.1007/s00233-024-10431-z).

[libsemigroups](https://libsemigroups.github.io/libsemigroups/) is partly based
on [Algorithms for computing finite semigroups](https://www.irif.fr/~jep/PDF/Rio.pdf),
[Expository Slides](https://www.irif.fr/~jep/PDF/Exposes/StAndrews.pdf), and
[Semigroupe 2.01](https://www.irif.fr/~jep/Logiciels/Semigroupe2.0/semigroupe2.html)
by [Jean-Eric Pin](https://www.irif.fr/~jep/).

## What is `Semigroups.jl`?

`Semigroups.jl` is a package for Julia 1.10+ exposing much (but not all) of
the functionality of [libsemigroups](https://libsemigroups.github.io/libsemigroups/).
It is built with the help of the excellent library
[CxxWrap.jl](https://github.com/JuliaInterop/CxxWrap.jl), for which we are
very grateful. A more detailed description of the structure of this package,
along with some associated quirks, is described on the
[exceptions page](package-info/exceptions.md).

The development version of `Semigroups.jl` is available on
[GitHub](https://github.com/libsemigroups/Semigroups.jl), and some related
projects are [here](https://github.com/libsemigroups).

## How to install `Semigroups.jl`?

To see how to install `Semigroups.jl`, see the
[installation page](package-info/installation.md).

## Issues

If you find any problems with `Semigroups.jl`, or have any suggestions for
features that you'd like to see, please use the
[issue tracker](https://github.com/libsemigroups/Semigroups.jl/issues).

## Acknowledgements

In addition to [libsemigroups](https://libsemigroups.github.io/libsemigroups/),
there are several excellent projects that are utilised in the development of
`Semigroups.jl`, specifically:

- [CxxWrap.jl](https://github.com/JuliaInterop/CxxWrap.jl) for Julia-C++ interop;
- [Documenter.jl](https://documenter.juliadocs.org/) for the documentation.

We would like to thank the authors and contributors of these projects!
