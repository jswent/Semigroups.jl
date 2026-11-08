# ASCII string words

```@meta
DocTestSetup = :(using Semigroups)
```

Presentations and congruence algorithms support two word representations:
positive integer vectors and ASCII strings. `Presentation()` keeps the integer
default; `Presentation("ab")` chooses string words with the ordered alphabet
`"ab"`. `Presentation{String}()` constructs an empty string presentation.

```jldoctest
julia> p = Presentation("a");

julia> add_rule!(p, "aa", "a");

julia> kb = KnuthBendix(twosided, p);

julia> guard = ReportGuard(false);

julia> Semigroups.reduce(kb, "aaa")
"a"

julia> (letter(p, 1), index_of(p, 'a'))
('a', 1)
```

Each character is a literal generator: `"aa"` is a word of length two, and
`"a^2"` is not exponent notation. ASCII control characters, including `\0`,
are valid generators. Non-ASCII characters are rejected rather than interpreted
as their UTF-8 bytes. General `AbstractString` inputs, including `SubString`,
are accepted; word results are ordinary owning `String` values.

The empty string is the empty word. Call `set_contains_empty_word!(p, true)`
when defining a quotient of a free monoid. Otherwise empty relation words and
empty algorithm query words are rejected. An empty alphabet and the empty word
are different concepts.

## Symbols, positions, and ordering

Letters are `Char` values in string presentations. Alphabet positions, rule
indices, graph nodes, and congruence class indices remain 1-based integers.
Alphabets contain distinct symbols. `set_alphabet!` changes the alphabet without
rewriting existing rules; `change_alphabet!` renames letters in the rules.

Todd–Coxeter, Knuth–Bendix, and `StringRange` use alphabet-position order:
with `"ba"`, `b` comes before `a`. Stand-alone string comparisons and presentation
sorting helpers use ASCII symbol order. Kambites reduction also uses native
symbol order, and its lexicographic reduced representative need not be the
shortlex representative produced by its normal-form iterator. Consequently,
arbitrary relabeling need not preserve the literal representative selected by
every algorithm.

## Converting representations

An algorithm inherits the word representation of its presentation. Its reductions,
rules, generating pairs, and word collections retain that representation, including
empty collections. Passing an integer word to a string algorithm, or the reverse,
requires explicit conversion.

`Semigroups.to(Presentation{Vector{Int}}, p)` and
`Semigroups.to(Presentation{String}, p)` change a presentation's representation.
Native default conversions relabel generators by alphabet position; they do not
retain arbitrary original labels. Supply `alphabet` to choose target labels:

```jldoctest
julia> p = Presentation("ba"); add_rule!(p, "bb", "a");

julia> q = Semigroups.to(Presentation{Vector{Int}}, p);

julia> rules(q)
1-element Vector{Tuple{Vector{Int64}, Vector{Int64}}}:
 ([1, 1], [2])

julia> Semigroups.to(Presentation{String}, q; alphabet="ba") == p
true

julia> ToWord("ba")("abba")
4-element Vector{Int64}:
 2
 1
 1
 2

julia> ToString("ba")([2, 1, 1, 2])
"abba"
```

`ToWord` and `ToString` convert words to and from **positions**, not arbitrary
integer presentation labels. Their explicit empty alphabet accepts only the
empty word; it does not request a default alphabet. Converters retain a snapshot
of their alphabet.

Graph edges and Froidure–Pin factorisations remain integer generator positions.
Use `Iterators.map(ToString("ab"), paths(g; source=1, max=3))` for a lazy string
view, or apply the converter to a factorisation. Presentation examples can be
converted with `Semigroups.to(Presentation{String}, example; alphabet=...)`.

## Ranges and ownership

`StringRange` mirrors the native range interface. Its upper length bound is
exclusive, and iteration consumes the range. Copy the range before iterating
if its current position must be retained.

```jldoctest
julia> r = StringRange("ba"); set_min!(r, 1); set_max!(r, 3);

julia> collect(r)
6-element Vector{String}:
 "b"
 "a"
 "bb"
 "ba"
 "ab"
 "aa"
```

Returned strings, presentations, and graph snapshots own their storage. Advancing
a native iterator or reinitializing the originating algorithm does not modify
previously returned values. Graph snapshots incur a copy of the graph.

Copying a `Congruence` preserves its mathematical input, including generating
pairs and any initial graph, with independent solver storage. If its internal
algorithm race has been initialized, the copy starts a fresh race instead of
sharing the original's solver progress.

Reduction and complete normal-form enumeration can run an algorithm to completion
and may not terminate. Kambites normal forms must be requested with an explicit
bound, `normal_forms(k, n)`; its unbounded form is unavailable.

## Native version limits

The public ASCII alphabet has at most 128 symbols. Operations creating new
generators reject exhaustion before modifying the presentation. One-sided string
Knuth–Bendix and Congruence require an unused symbol before adding generating pairs.

Two libsemigroups 3.6.1 defaults have narrower limits: string `set_alphabet!(p, n)`
uses consecutive bytes starting at `'a'`, so `n ≤ 31`; converting a plain string
presentation to an inverse presentation uses that convention for twice as many
generators, so the source has at most 15 generators. Explicit alphabets avoid
the count-based setter restriction. These limits preserve the pinned native
version's labeling behavior.

## API

```@docs
Semigroups.StringRange
Semigroups.ToWord
Semigroups.ToString
Semigroups.Congruence
Semigroups.to
Semigroups.random_word(::AbstractString, ::Integer)
Semigroups.weighted_shortlex_less(::AbstractString, ::AbstractString, ::AbstractVector{<:Integer})
```

This implementation, documentation, and its regression tests were prepared with
OpenAI Codex assistance for binding design, coding, and verification.
