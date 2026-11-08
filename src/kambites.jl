# Copyright (c) 2026, James W. Swent
#
# Distributed under the terms of the GPL license version 3.

"""
kambites.jl - Kambites wrapper (Layer 2 + 3)
"""

# ============================================================================
# Type alias
# ============================================================================

"""
    Kambites

Type implementing small overlap class, equality, and normal forms for
small overlap monoids -- finitely presented monoids whose presentation
satisfies the small overlap condition `C(n)` for `n >= 4` (Kambites,
2009).

A [`Kambites`](@ref Semigroups.Kambites) instance represents a
congruence on the free monoid or semigroup containing the rules of the
[`Presentation`](@ref Semigroups.Presentation) used to construct the
instance, together with the
[`generating_pairs`](@ref Semigroups.generating_pairs) added via
[`add_generating_pair!`](@ref Semigroups.add_generating_pair!). As such,
generating pairs and presentation rules are interchangeable in the
context of `Kambites` objects.

A `Kambites` object is constructed from a
[`congruence_kind`](@ref Semigroups.congruence_kind) (which must be
[`twosided`](@ref Semigroups.twosided)) and a
[`Presentation`](@ref Semigroups.Presentation), or copied from another
`Kambites`.

`Kambites` is a subtype of
[`CongruenceCommon`](@ref Semigroups.CongruenceCommon) (and hence of
[`Runner`](@ref Semigroups.Runner)), so all runner methods (`run!`,
`run_for!`, `finished`, `timed_out`, etc.) and most common congruence
helpers ([`reduce`](@ref Semigroups.reduce),
[`contains`](@ref Semigroups.contains),
[`currently_contains`](@ref Semigroups.currently_contains),
[`add_generating_pair!`](@ref Semigroups.add_generating_pair!),
[`partition`](@ref Semigroups.partition)) work on `Kambites` objects.

# Structural deviations from `KnuthBendix` / `ToddCoxeter` precedent

- `Base.length` is intentionally **not** defined for `Kambites`. The
  number of classes is always
  [`POSITIVE_INFINITY`](@ref Semigroups.POSITIVE_INFINITY) (or throws),
  so an alias would silently misbehave with `for i in 1:length(k)`.
  Use [`number_of_classes`](@ref Semigroups.number_of_classes)
  explicitly.
- [`non_trivial_classes`](@ref Semigroups.non_trivial_classes)`(k1::Kambites, k2::Kambites)`
  throws `ArgumentError` (upstream rationale: both `Kambites` instances
  always represent infinite-class congruences, so the construction does
  not generalize; cf. `kambites-helpers.hpp:128-133`).
- [`normal_forms`](@ref Semigroups.normal_forms)`(k::Kambites)` (no-arg)
  throws `ArgumentError` because the underlying normal-form range is
  infinite. Use the bounded form `normal_forms(k, n)` to materialize
  the first `n` normal forms.
- The `ukkonen()` accessor (and the `Ukkonen` type) is deferred to a
  later release

# Constructors

    Kambites() -> Kambites
    Kambites(kind::congruence_kind, p::Presentation) -> Kambites
    Kambites(k::Kambites) -> Kambites

# Throws

- [`LibsemigroupsError`](@ref Semigroups.LibsemigroupsError) if `kind`
  is not [`twosided`](@ref Semigroups.twosided).

Words use the representation of the input presentation: integer vectors or ASCII strings.
"""
struct Kambites{W,B} <: CongruenceCommon{W}
    cxx_obj::B
end

_native_algorithm(::Type{Kambites}, ::Type{Vector{Int}}) = LibSemigroups.KambitesWord
_native_algorithm(::Type{Kambites}, ::Type{String}) = LibSemigroups.KambitesString
_wrap_kambites(x::LibSemigroups.KambitesWord) = Kambites{Vector{Int},typeof(x)}(x)
_wrap_kambites(x::LibSemigroups.KambitesString) = Kambites{String,typeof(x)}(x)
Kambites{W}() where {W} = _wrap_kambites(_native_algorithm(Kambites, W)())
Kambites() = Kambites{Vector{Int}}()
Kambites(other::Kambites{W}) where {W} =
    _wrap_kambites(@wrap_libsemigroups_call _native_algorithm(Kambites, W)(_native(other)))


# ============================================================================
# Initialization
# ============================================================================

"""
    Kambites(kind::congruence_kind, p::Presentation) -> Kambites

Construct a [`Kambites`](@ref Semigroups.Kambites) instance representing
a congruence of kind `kind` over the semigroup or monoid defined by the
presentation `p`.

`Kambites` instances can only be used to compute two-sided congruences,
so `kind` must always be [`twosided`](@ref Semigroups.twosided). The
parameter is included for uniformity of interface with
[`KnuthBendix`](@ref Semigroups.KnuthBendix), `ToddCoxeter`, and
`Congruence`.

This Julia wrapper builds a default `Kambites` and then calls
[`init!`](@ref Semigroups.init!) so that exceptions raised by
libsemigroups surface as
[`LibsemigroupsError`](@ref Semigroups.LibsemigroupsError) (the direct
CxxWrap-bound constructor would surface them as `Base.ErrorException`).

# Throws

- [`LibsemigroupsError`](@ref Semigroups.LibsemigroupsError) if `p` is
  not valid.
- [`LibsemigroupsError`](@ref Semigroups.LibsemigroupsError) if `kind`
  is not [`twosided`](@ref Semigroups.twosided).
"""
function Kambites(kind::congruence_kind, p::Presentation{W}) where {W}
    k = Kambites{W}()
    init!(k, kind, p)
    return k
end

"""
    init!(k::Kambites) -> Kambites
    init!(k::Kambites, kind::congruence_kind, p::Presentation) -> Kambites

Re-initialize `k` so that it is in the state it would have been in
immediately after the corresponding constructor.

The one-argument form puts `k` back into the same state as a newly
default-constructed [`Kambites`](@ref Semigroups.Kambites).

The three-argument form puts `k` back into the state it would have been
in if it had just been newly constructed from `kind` and `p`.
`Kambites` instances can only be used to compute two-sided congruences,
so `kind` must always be [`twosided`](@ref Semigroups.twosided); the
parameter is included for uniformity of interface with
[`KnuthBendix`](@ref Semigroups.KnuthBendix), `ToddCoxeter`, and
`Congruence`.

Returns `k` for chaining.

# Throws

- [`LibsemigroupsError`](@ref Semigroups.LibsemigroupsError) if `p` is
  not valid (three-argument form only).
- [`LibsemigroupsError`](@ref Semigroups.LibsemigroupsError) if `kind`
  is not [`twosided`](@ref Semigroups.twosided) (three-argument form
  only).
"""
function init!(k::Kambites)
    @wrap_libsemigroups_call LibSemigroups.init!(_native(k))
    return k
end

function init!(k::Kambites, kind::congruence_kind, p::Presentation)
    _require_same_word_type(k, p)
    @wrap_libsemigroups_call LibSemigroups.init!(_native(k), kind, _native(p))
    return k
end

# ============================================================================
# Accessors
# ============================================================================

"""
    presentation(k::Kambites) -> Presentation

Return a copy of the [`Presentation`](@ref Semigroups.Presentation) used
to construct or initialize `k` (if any).

If `k` was constructed or initialized using a presentation, that
presentation is returned. The Julia binding returns by value (an
independent copy) rather than by reference; mutating the returned
object does not affect `k`.
"""
presentation(k::Kambites) = _wrap_presentation(LibSemigroups.presentation(_native(k)))

"""
    generating_pairs(k::Kambites) -> Vector{Tuple{Vector{Int}, Vector{Int}}}

Return the generating pairs of `k` as a vector of 1-based word pairs.

These are the pairs added via
[`add_generating_pair!`](@ref Semigroups.add_generating_pair!). Each pair
`(u, v)` is returned as a 2-tuple of 1-based `Vector{Int}` letter
indices. The length of the returned vector equals
[`number_of_generating_pairs`](@ref Semigroups.number_of_generating_pairs).
"""
function generating_pairs(k::Kambites)
    flat = LibSemigroups.generating_pairs(_native(k))
    return _word_pairs_from_cpp(_word_type(k), flat)
end

"""
    kind(k::Kambites) -> congruence_kind

Return the kind of congruence (one- or two-sided) represented by `k`;
see [`congruence_kind`](@ref Semigroups.congruence_kind) for details.
For [`Kambites`](@ref Semigroups.Kambites) this is always
[`twosided`](@ref Semigroups.twosided), since the constructor enforces
that constraint.

Complexity: constant.
"""
kind(k::Kambites) = LibSemigroups.kind(_native(k))

"""
    number_of_generating_pairs(k::Kambites) -> Int

Return the number of generating pairs added to `k`. Equals the length
of [`generating_pairs`](@ref Semigroups.generating_pairs)`(k)`.

Complexity: constant.
"""
number_of_generating_pairs(k::Kambites) =
    Int(LibSemigroups.number_of_generating_pairs(_native(k)))

"""
    number_of_classes(k::Kambites) -> UInt64

Compute the number of congruence classes of `k`.

`Kambites` instances can only compute the number of classes when
[`small_overlap_class`](@ref Semigroups.small_overlap_class) is at
least 4, and in that case the number is always
[`POSITIVE_INFINITY`](@ref Semigroups.POSITIVE_INFINITY); otherwise an
exception is thrown. Use
[`is_positive_infinity`](@ref Semigroups.is_positive_infinity) (or
direct comparison `result == POSITIVE_INFINITY`) to detect the infinite
case.

# Throws

- [`LibsemigroupsError`](@ref Semigroups.LibsemigroupsError) if it is
  not possible to compute the number of classes because the small
  overlap class is too small (`small_overlap_class(k) < 4`).
"""
number_of_classes(k::Kambites) =
    @wrap_libsemigroups_call LibSemigroups.number_of_classes(_native(k))

# ============================================================================
# small_overlap_class (const-overload split)
# ============================================================================

"""
    small_overlap_class(k::Kambites) -> UInt64

Get the small overlap class of the [`Presentation`](@ref
Semigroups.Presentation) underlying `k`.

If ``S`` is a finitely presented semigroup with generating set ``A``,
then a word ``w`` over ``A`` is a *piece* if ``w`` occurs as a factor
in at least two of the relations defining ``S``, or if it occurs as a
factor of one relation in two different positions (possibly
overlapping). A finitely presented semigroup ``S`` satisfies the
condition ``C(n)`` for a positive integer ``n`` if the minimum number
of pieces in any factorisation of a word occurring as the left or
right hand side of a relation is at least ``n``.

This function returns the greatest positive integer `n` such that the
finitely presented semigroup represented by `k` satisfies the
condition ``C(n)``, or
[`POSITIVE_INFINITY`](@ref Semigroups.POSITIVE_INFINITY) if no word
occurring in a relation can be written as a product of pieces. It may
trigger computation.

The return type is `UInt64` (rather than `Int`) because
[`POSITIVE_INFINITY`](@ref Semigroups.POSITIVE_INFINITY) is encoded as
`typemax(UInt64) - 1` on the wire and would not round-trip through
`Int`. Use [`is_positive_infinity`](@ref Semigroups.is_positive_infinity)
(or direct comparison `result == POSITIVE_INFINITY`) to detect the
infinite case.

Complexity: ``O(m^3)``, where ``m`` is the sum of the lengths of the
words occurring in the relations of the semigroup.

!!! warning
    [`Semigroups.contains`](@ref Semigroups.contains) and
    [`Semigroups.reduce`](@ref Semigroups.reduce) only work if the
    return value of this function is at least 4.

# See also

[`current_small_overlap_class`](@ref Semigroups.current_small_overlap_class)
"""
small_overlap_class(k::Kambites) = LibSemigroups.small_overlap_class(_native(k))

"""
    current_small_overlap_class(k::Kambites) -> Union{UInt64, UndefinedType}

Get the current value of the small overlap class of `k`, if known.

Returns the small overlap class if it has already been computed, or
[`UNDEFINED`](@ref Semigroups.UNDEFINED) otherwise. This function does
not trigger any computation. The known value is returned as `UInt64`
(see [`small_overlap_class`](@ref Semigroups.small_overlap_class) for
the rationale).

See [`small_overlap_class`](@ref Semigroups.small_overlap_class) for
more details on what the small overlap class is.

# See also

[`small_overlap_class`](@ref Semigroups.small_overlap_class)
"""
function current_small_overlap_class(k::Kambites)
    val = LibSemigroups.current_small_overlap_class(_native(k))
    return val == convert(UInt, UNDEFINED) ? UNDEFINED : val
end

# ============================================================================
# Validators
# ============================================================================

"""
    throw_if_letter_not_in_alphabet(k::Kambites, w::AbstractVector{<:Integer})

Throw if any letter in `w` is out of bounds.

This function throws a
[`LibsemigroupsError`](@ref Semigroups.LibsemigroupsError) if any
letter of `w` is out of bounds -- i.e. does not belong to the alphabet
of the [`Presentation`](@ref Semigroups.Presentation) used to
construct `k`. Letters in `w` are 1-based indices.

# Arguments

- `k::Kambites`: the [`Kambites`](@ref Semigroups.Kambites) instance.
- `w::AbstractVector{<:Integer}`: the word to check.

# Throws

- [`LibsemigroupsError`](@ref Semigroups.LibsemigroupsError) if any
  letter in `w` is not in the alphabet.
"""
function throw_if_letter_not_in_alphabet(
    k::Kambites,
    w::Union{AbstractVector{<:Integer},AbstractString},
)
    cpp_w = _word_to_cpp(_word_type(k), w)
    @wrap_libsemigroups_call LibSemigroups.throw_if_letter_not_in_alphabet(
        _native(k),
        cpp_w,
    )
    return nothing
end

"""
    throw_if_not_C4(k::Kambites)

Throw if the [`small_overlap_class`](@ref Semigroups.small_overlap_class)
of `k` is not at least 4.

This function throws an exception if the small overlap class of `k` is
not at least 4 (and computes it if necessary).

# Throws

- [`LibsemigroupsError`](@ref Semigroups.LibsemigroupsError) if
  `small_overlap_class(k) < 4`.
"""
function throw_if_not_C4(k::Kambites)
    @wrap_libsemigroups_call LibSemigroups.throw_if_not_C4(_native(k))
    return nothing
end

# ============================================================================
# Base.* overloads
# ============================================================================

"""
    Base.show(io::IO, k::Kambites)

Print a human-readable representation of `k`. Delegates to
libsemigroups' `to_human_readable_repr`.
"""
function Base.show(io::IO, k::Kambites)
    print(io, LibSemigroups.to_human_readable_repr(_native(k)))
end

"""
    Base.copy(k::Kambites) -> Kambites

Create an independent copy of `k` via the C++ copy constructor.
"""
Base.copy(k::Kambites) = Kambites(k)

Base.deepcopy_internal(k::Kambites, ::IdDict) = Kambites(k)

# ============================================================================
# non_trivial_classes override (throws)
# ============================================================================

"""
    non_trivial_classes(k1::Kambites, k2::Kambites)

Always throws `ArgumentError` for [`Kambites`](@ref Semigroups.Kambites)
arguments.

`non_trivial_classes(Kambites, Kambites)` is intentionally not provided
upstream (see `kambites-helpers.hpp:128-133`) because both `Kambites`
instances always represent infinite-class congruences, so the
construction does not generalize.
"""
function non_trivial_classes(::Kambites, ::Kambites)
    throw(
        ArgumentError(
            "non_trivial_classes(::Kambites, ::Kambites) is intentionally not " *
            "supported: both Kambites instances always represent infinite-class " *
            "congruences, so the construction does not generalize " *
            "(see kambites-helpers.hpp:128-133).",
        ),
    )
end

# ============================================================================
# normal_forms (bounded; the no-arg form throws)
# ============================================================================

"""
    normal_forms(k::Kambites, n::Integer) -> Vector{Vector{Int}}

Return the first `n` short-lex normal forms of the classes of the
congruence represented by `k`, as 1-based `Vector{Int}` words.

The underlying range of normal forms is always infinite (one per
congruence class, and a `C(>=4)` presentation has infinitely many
classes), so the caller must specify the bound `n`. The bounded form
materializes only the first `n` words and is safe to call.

# Throws

- [`LibsemigroupsError`](@ref Semigroups.LibsemigroupsError) if
  `small_overlap_class(k) < 4`.
- `InexactError` if `n` is negative.
"""
function normal_forms(k::Kambites, n::Integer)
    cpp_n = UInt(n)
    nf =
        @wrap_libsemigroups_call LibSemigroups.kambites_normal_forms_take(_native(k), cpp_n)
    return _words_from_cpp(_word_type(k), nf)
end

"""
    normal_forms(k::Kambites)

Always throws `ArgumentError`. The set of normal forms of a `Kambites`
is infinite, so the no-argument form is unsafe; use the bounded form
[`normal_forms(k, n)`](@ref Semigroups.normal_forms(::Kambites, ::Integer))
instead.
"""
function normal_forms(k::Kambites)
    throw(
        ArgumentError(
            "Kambites has infinitely many normal forms; use normal_forms(k, n) " *
            "to take the first n.",
        ),
    )
end
