# Copyright (c) 2026, James W. Swent
#
# Distributed under the terms of the GPL license version 3.
# OpenAI Codex assisted with public presentation result wrapping.

"""
presentation-examples.jl - Julia wrappers for `libsemigroups::presentation::examples`

Each binding returns a fresh [`Presentation`](@ref Semigroups.Presentation)
over `word_type`, exposed in Julia as `Vector{Int}` words with 1-based
letter indices. These wrappers mirror the default
`libsemigroups::presentation::examples` constructors.

!!! note "Argument conversion"
    Most integer parameters are converted to the corresponding C++
    `size_t` values with `UInt(...)` before the libsemigroups call, and
    the Renner-family `q` parameters are converted with `Int32(...)`.
    Negative or otherwise unrepresentable inputs therefore raise
    `InexactError` in Julia before `libsemigroups` can throw
    `LibsemigroupsError`.

These constructors use numeric words. Use an explicit presentation conversion
to assign a string alphabet to the resulting presentation.
"""

"""
    symmetric_group(n::Integer) -> Presentation

A presentation for the symmetric group of degree `n`.

This function returns the default libsemigroups presentation of the
symmetric group of degree `n`.

# Arguments
- `n::Integer`: the degree of the symmetric group.

# Throws
- `InexactError`: if `n` is negative.
- `LibsemigroupsError`: if `n < 2`.
"""
function symmetric_group(n::Integer)
    m = UInt(n)
    native = @wrap_libsemigroups_call LibSemigroups.example_symmetric_group(m)
    return _wrap_presentation(native)
end

"""
    alternating_group(n::Integer) -> Presentation

A presentation for the alternating group of degree `n`.

This function returns a monoid presentation defining the alternating
group of degree `n`.

# Arguments
- `n::Integer`: the degree of the alternating group.

# Throws
- `InexactError`: if `n` is negative.
- `LibsemigroupsError`: if `n < 4`.
"""
function alternating_group(n::Integer)
    m = UInt(n)
    native = @wrap_libsemigroups_call LibSemigroups.example_alternating_group(m)
    return _wrap_presentation(native)
end

"""
    braid_group(n::Integer) -> Presentation

A presentation for the braid group with `n - 1` generators.

This function returns a monoid presentation defining the braid group with
`n - 1` generators.

# Arguments
- `n::Integer`: the degree, or equivalently the number of generators plus `1`.

# Throws
- `InexactError`: if `n` is negative.
- `LibsemigroupsError`: if `n < 3`.
"""
function braid_group(n::Integer)
    m = UInt(n)
    native = @wrap_libsemigroups_call LibSemigroups.example_braid_group(m)
    return _wrap_presentation(native)
end

"""
    not_symmetric_group(n::Integer) -> Presentation

A presentation that is not a symmetric group but has the same number of
generators and relations as the symmetric group of degree `n`.

This function returns a monoid presentation which is claimed to define
the symmetric group of degree `n`, but does not.

# Arguments
- `n::Integer`: the claimed degree of the symmetric group.

# Throws
- `InexactError`: if `n` is negative.
- `LibsemigroupsError`: if `n < 4`.
"""
function not_symmetric_group(n::Integer)
    m = UInt(n)
    native = @wrap_libsemigroups_call LibSemigroups.example_not_symmetric_group(m)
    return _wrap_presentation(native)
end

"""
    full_transformation_monoid(n::Integer) -> Presentation

A presentation for the full transformation monoid of degree `n`.

This function returns the default libsemigroups presentation of the full
transformation monoid of degree `n`.

# Arguments
- `n::Integer`: the degree of the full transformation monoid.

# Throws
- `InexactError`: if `n` is negative.
- `LibsemigroupsError`: if `n < 2`.
"""
function full_transformation_monoid(n::Integer)
    m = UInt(n)
    native = @wrap_libsemigroups_call LibSemigroups.example_full_transformation_monoid(m)
    return _wrap_presentation(native)
end

"""
    partial_transformation_monoid(n::Integer) -> Presentation

A presentation for the partial transformation monoid of degree `n`.

This function returns the default libsemigroups presentation of the
partial transformation monoid of degree `n`.

# Arguments
- `n::Integer`: the degree of the partial transformation monoid.

# Throws
- `InexactError`: if `n` is negative.
- `LibsemigroupsError`: if `n < 2`.
"""
function partial_transformation_monoid(n::Integer)
    m = UInt(n)
    native = @wrap_libsemigroups_call LibSemigroups.example_partial_transformation_monoid(m)
    return _wrap_presentation(native)
end

"""
    symmetric_inverse_monoid(n::Integer) -> Presentation

A presentation for the symmetric inverse monoid of degree `n`.

This function returns the default libsemigroups presentation of the
symmetric inverse monoid of degree `n`.

# Arguments
- `n::Integer`: the degree of the symmetric inverse monoid.

# Throws
- `InexactError`: if `n` is negative.
- `LibsemigroupsError`: if `n < 4`.
"""
function symmetric_inverse_monoid(n::Integer)
    m = UInt(n)
    native = @wrap_libsemigroups_call LibSemigroups.example_symmetric_inverse_monoid(m)
    return _wrap_presentation(native)
end

"""
    cyclic_inverse_monoid(n::Integer) -> Presentation

A presentation for the cyclic inverse monoid of degree `n`.

This function returns the default libsemigroups presentation of the
cyclic inverse monoid of degree `n`.

# Arguments
- `n::Integer`: the degree of the cyclic inverse monoid.

# Throws
- `InexactError`: if `n` is negative.
- `LibsemigroupsError`: if `n < 3`.
"""
function cyclic_inverse_monoid(n::Integer)
    m = UInt(n)
    native = @wrap_libsemigroups_call LibSemigroups.example_cyclic_inverse_monoid(m)
    return _wrap_presentation(native)
end

"""
    order_preserving_monoid(n::Integer) -> Presentation

A presentation for the order-preserving transformation monoid of degree `n`.

This function returns a presentation for the monoid of order-preserving
transformations of degree `n`.

# Arguments
- `n::Integer`: the degree.

# Throws
- `InexactError`: if `n` is negative.
- `LibsemigroupsError`: if `n < 3`.
"""
function order_preserving_monoid(n::Integer)
    m = UInt(n)
    native = @wrap_libsemigroups_call LibSemigroups.example_order_preserving_monoid(m)
    return _wrap_presentation(native)
end

"""
    order_preserving_cyclic_inverse_monoid(n::Integer) -> Presentation

A presentation for the order-preserving part of the cyclic inverse monoid of
degree `n`.

This function returns a presentation for the order-preserving part of the
cyclic inverse monoid of degree `n`.

# Arguments
- `n::Integer`: the degree.

# Throws
- `InexactError`: if `n` is negative.
- `LibsemigroupsError`: if `n < 3`.
"""
function order_preserving_cyclic_inverse_monoid(n::Integer)
    m = UInt(n)
    native =
        @wrap_libsemigroups_call LibSemigroups.example_order_preserving_cyclic_inverse_monoid(
            m,
        )
    return _wrap_presentation(native)
end

"""
    orientation_preserving_monoid(n::Integer) -> Presentation

A presentation for the orientation-preserving transformation monoid of degree
`n`.

This function returns a presentation for the orientation-preserving
transformation monoid of degree `n`.

# Arguments
- `n::Integer`: the degree.

# Throws
- `InexactError`: if `n` is negative.
- `LibsemigroupsError`: if `n < 3`.
"""
function orientation_preserving_monoid(n::Integer)
    m = UInt(n)
    native = @wrap_libsemigroups_call LibSemigroups.example_orientation_preserving_monoid(m)
    return _wrap_presentation(native)
end

"""
    orientation_preserving_reversing_monoid(n::Integer) -> Presentation

A presentation for the orientation-preserving and -reversing transformation
monoid of degree `n`.

This function returns a presentation for the orientation-preserving and
orientation-reversing transformation monoid of degree `n`.

# Arguments
- `n::Integer`: the degree.

# Throws
- `InexactError`: if `n` is negative.
- `LibsemigroupsError`: if `n < 3`.
"""
function orientation_preserving_reversing_monoid(n::Integer)
    m = UInt(n)
    native =
        @wrap_libsemigroups_call LibSemigroups.example_orientation_preserving_reversing_monoid(
            m,
        )
    return _wrap_presentation(native)
end

"""
    partition_monoid(n::Integer) -> Presentation

A presentation for the partition monoid of degree `n`.

This function returns the default libsemigroups presentation of the
partition monoid of degree `n`.

# Arguments
- `n::Integer`: the degree of the partition monoid.

# Throws
- `InexactError`: if `n` is negative.
- `LibsemigroupsError`: if `n < 4`.
"""
function partition_monoid(n::Integer)
    m = UInt(n)
    native = @wrap_libsemigroups_call LibSemigroups.example_partition_monoid(m)
    return _wrap_presentation(native)
end

"""
    partial_brauer_monoid(n::Integer) -> Presentation

A presentation for the partial Brauer monoid of degree `n`.

This function returns the default libsemigroups presentation of the
partial Brauer monoid of degree `n`.

# Arguments
- `n::Integer`: the degree of the partial Brauer monoid.

# Throws
- `InexactError`: if `n` is negative.
- `LibsemigroupsError`: if `n < 1`.
"""
function partial_brauer_monoid(n::Integer)
    m = UInt(n)
    native = @wrap_libsemigroups_call LibSemigroups.example_partial_brauer_monoid(m)
    return _wrap_presentation(native)
end

"""
    brauer_monoid(n::Integer) -> Presentation

A presentation for the Brauer monoid of degree `n`.

This function returns the default libsemigroups presentation of the
Brauer monoid of degree `n`.

# Arguments
- `n::Integer`: the degree of the Brauer monoid.

# Throws
- `InexactError`: if `n` is negative.
- `LibsemigroupsError`: if `n < 1`.
"""
function brauer_monoid(n::Integer)
    m = UInt(n)
    native = @wrap_libsemigroups_call LibSemigroups.example_brauer_monoid(m)
    return _wrap_presentation(native)
end

"""
    singular_brauer_monoid(n::Integer) -> Presentation

A presentation for the singular part of the Brauer monoid of degree `n`.

This function returns a monoid presentation for the singular part of the
Brauer monoid of degree `n`.

# Arguments
- `n::Integer`: the degree.

# Throws
- `InexactError`: if `n` is negative.
- `LibsemigroupsError`: if `n < 3`.
"""
function singular_brauer_monoid(n::Integer)
    m = UInt(n)
    native = @wrap_libsemigroups_call LibSemigroups.example_singular_brauer_monoid(m)
    return _wrap_presentation(native)
end

"""
    temperley_lieb_monoid(n::Integer) -> Presentation

A presentation for the Temperley-Lieb monoid with `n - 1` generators.

This function returns a monoid presentation defining the Temperley-Lieb
monoid with `n - 1` generators.

# Arguments
- `n::Integer`: the degree, or equivalently the number of generators plus `1`.

# Throws
- `InexactError`: if `n` is negative.
- `LibsemigroupsError`: if `n < 3`.
"""
function temperley_lieb_monoid(n::Integer)
    m = UInt(n)
    native = @wrap_libsemigroups_call LibSemigroups.example_temperley_lieb_monoid(m)
    return _wrap_presentation(native)
end

"""
    motzkin_monoid(n::Integer) -> Presentation

A presentation for the Motzkin monoid of degree `n`.

This function returns a monoid presentation defining the Motzkin monoid of
degree `n`.

# Arguments
- `n::Integer`: the degree.

# Throws
- `InexactError`: if `n` is negative.
- `LibsemigroupsError`: if `n < 1`.
"""
function motzkin_monoid(n::Integer)
    m = UInt(n)
    native = @wrap_libsemigroups_call LibSemigroups.example_motzkin_monoid(m)
    return _wrap_presentation(native)
end

"""
    partial_isometries_cycle_graph_monoid(n::Integer) -> Presentation

A presentation for the monoid of partial isometries of an `n`-cycle graph.

This function returns the default libsemigroups presentation of the
monoid of partial isometries of an `n`-cycle graph.

# Arguments
- `n::Integer`: the degree of the cycle graph.

# Throws
- `InexactError`: if `n` is negative.
- `LibsemigroupsError`: if `n < 3`.
"""
function partial_isometries_cycle_graph_monoid(n::Integer)
    m = UInt(n)
    native =
        @wrap_libsemigroups_call LibSemigroups.example_partial_isometries_cycle_graph_monoid(
            m,
        )
    return _wrap_presentation(native)
end

"""
    uniform_block_bijection_monoid(n::Integer) -> Presentation

A presentation for the uniform block bijection monoid of degree `n`.

This function returns the default libsemigroups presentation of the
uniform block bijection monoid of degree `n`.

# Arguments
- `n::Integer`: the degree of the monoid.

# Throws
- `InexactError`: if `n` is negative.
- `LibsemigroupsError`: if `n < 3`.
"""
function uniform_block_bijection_monoid(n::Integer)
    m = UInt(n)
    native =
        @wrap_libsemigroups_call LibSemigroups.example_uniform_block_bijection_monoid(m)
    return _wrap_presentation(native)
end

"""
    dual_symmetric_inverse_monoid(n::Integer) -> Presentation

A presentation for the dual symmetric inverse monoid of degree `n`.

This function returns the default libsemigroups presentation of the
dual symmetric inverse monoid of degree `n`.

# Arguments
- `n::Integer`: the degree of the monoid.

# Throws
- `InexactError`: if `n` is negative.
- `LibsemigroupsError`: if `n < 3`.
"""
function dual_symmetric_inverse_monoid(n::Integer)
    m = UInt(n)
    native = @wrap_libsemigroups_call LibSemigroups.example_dual_symmetric_inverse_monoid(m)
    return _wrap_presentation(native)
end

"""
    stellar_monoid(l::Integer) -> Presentation

A presentation for the stellar monoid with `l` generators.

This function returns a monoid presentation defining the stellar monoid
with `l` generators.

# Arguments
- `l::Integer`: the number of generators.

# Throws
- `InexactError`: if `l` is negative.
- `LibsemigroupsError`: if `l < 2`.
"""
function stellar_monoid(l::Integer)
    ll = UInt(l)
    native = @wrap_libsemigroups_call LibSemigroups.example_stellar_monoid(ll)
    return _wrap_presentation(native)
end

"""
    zero_rook_monoid(n::Integer) -> Presentation

A presentation for the 0-rook monoid of degree `n`.

This function returns the default libsemigroups presentation of the
0-rook monoid of degree `n`.

# Arguments
- `n::Integer`: the degree of the monoid.

# Throws
- `InexactError`: if `n` is negative.
- `LibsemigroupsError`: if `n < 2`.
"""
function zero_rook_monoid(n::Integer)
    m = UInt(n)
    native = @wrap_libsemigroups_call LibSemigroups.example_zero_rook_monoid(m)
    return _wrap_presentation(native)
end

"""
    abacus_jones_monoid(n::Integer, d::Integer) -> Presentation

A presentation for the abacus Jones monoid of degree `n` with at most `d-1`
beads per arc.

This function returns a monoid presentation defining the abacus Jones
monoid of degree `n`, where each arc carries at most `d - 1` beads.

# Arguments
- `n::Integer`: the degree.
- `d::Integer`: one more than the maximum number of beads on each arc.

# Throws
- `InexactError`: if `n` or `d` is negative.
- `LibsemigroupsError`: if `n < 3`.
- `LibsemigroupsError`: if `d == 0`.
"""
function abacus_jones_monoid(n::Integer, d::Integer)
    nn = UInt(n)
    dd = UInt(d)
    native = @wrap_libsemigroups_call LibSemigroups.example_abacus_jones_monoid(nn, dd)
    return _wrap_presentation(native)
end

# ---- batch C: plactic / misc ----

"""
    plactic_monoid(n::Integer) -> Presentation

A presentation for the plactic monoid with `n` generators.

This function returns a monoid presentation defining the plactic monoid
with `n` generators.

# Arguments
- `n::Integer`: the number of generators.

# Throws
- `InexactError`: if `n` is negative.
- `LibsemigroupsError`: if `n < 1`.
"""
function plactic_monoid(n::Integer)
    m = UInt(n)
    native = @wrap_libsemigroups_call LibSemigroups.example_plactic_monoid(m)
    return _wrap_presentation(native)
end

"""
    chinese_monoid(n::Integer) -> Presentation

A presentation for the Chinese monoid with `n` generators.

This function returns a monoid presentation defining the Chinese monoid
with `n` generators.

# Arguments
- `n::Integer`: the number of generators.

# Throws
- `InexactError`: if `n` is negative.
- `LibsemigroupsError`: if `n < 2`.
"""
function chinese_monoid(n::Integer)
    m = UInt(n)
    native = @wrap_libsemigroups_call LibSemigroups.example_chinese_monoid(m)
    return _wrap_presentation(native)
end

"""
    hypo_plactic_monoid(n::Integer) -> Presentation

A presentation for the hypo-plactic monoid with `n` generators.

This function returns a presentation for the hypo-plactic monoid with `n`
generators. It is a quotient monoid of the plactic monoid.

# Arguments
- `n::Integer`: the number of generators.

# Throws
- `InexactError`: if `n` is negative.
- `LibsemigroupsError`: if `n < 1`.
"""
function hypo_plactic_monoid(n::Integer)
    m = UInt(n)
    native = @wrap_libsemigroups_call LibSemigroups.example_hypo_plactic_monoid(m)
    return _wrap_presentation(native)
end

"""
    stylic_monoid(n::Integer) -> Presentation

A presentation for the stylic monoid with `n` generators.

This function returns a monoid presentation defining the stylic monoid
with `n` generators.

# Arguments
- `n::Integer`: the number of generators.

# Throws
- `InexactError`: if `n` is negative.
- `LibsemigroupsError`: if `n < 2`.
"""
function stylic_monoid(n::Integer)
    m = UInt(n)
    native = @wrap_libsemigroups_call LibSemigroups.example_stylic_monoid(m)
    return _wrap_presentation(native)
end

"""
    special_linear_group_2(q::Integer) -> Presentation

A presentation for the special linear group SL(2, q).

This function returns a presentation for the special linear group
`SL(2, q)`, where `q` should be an odd prime for the returned
presentation to define the claimed group.

# Arguments
- `q::Integer`: the order of the finite field.

# Throws
- `InexactError`: if `q` is negative.
- `LibsemigroupsError`: if `q < 3`.
"""
function special_linear_group_2(q::Integer)
    qq = UInt(q)
    native = @wrap_libsemigroups_call LibSemigroups.example_special_linear_group_2(qq)
    return _wrap_presentation(native)
end

"""
    fibonacci_semigroup(r::Integer, n::Integer) -> Presentation

A presentation for the Fibonacci semigroup F(r, n).

This function returns a semigroup presentation defining the Fibonacci
semigroup `F(r, n)`.

# Arguments
- `r::Integer`: the length of the left-hand sides of the relations.
- `n::Integer`: the number of generators.

# Throws
- `InexactError`: if `r` or `n` is negative.
- `LibsemigroupsError`: if `r < 1`.
- `LibsemigroupsError`: if `n < 1`.
"""
function fibonacci_semigroup(r::Integer, n::Integer)
    rr = UInt(r)
    nn = UInt(n)
    native = @wrap_libsemigroups_call LibSemigroups.example_fibonacci_semigroup(rr, nn)
    return _wrap_presentation(native)
end

"""
    monogenic_semigroup(m::Integer, r::Integer) -> Presentation

A presentation for the monogenic semigroup with index `m` and period `r`.

This function returns the presentation `<a | a^(m + r) = a^m>`. When
`m == 0` the result is a monoid presentation; otherwise it is a
semigroup presentation.

# Arguments
- `m::Integer`: the index.
- `r::Integer`: the period.

# Throws
- `InexactError`: if `m` or `r` is negative.
- `LibsemigroupsError`: if `r == 0`.
"""
function monogenic_semigroup(m::Integer, r::Integer)
    mm = UInt(m)
    rr = UInt(r)
    native = @wrap_libsemigroups_call LibSemigroups.example_monogenic_semigroup(mm, rr)
    return _wrap_presentation(native)
end

"""
    rectangular_band(m::Integer, n::Integer) -> Presentation

A presentation for the ``m \\times n`` rectangular band.

This function returns a semigroup presentation defining the `m` by `n`
rectangular band.

# Arguments
- `m::Integer`: the number of rows.
- `n::Integer`: the number of columns.

# Throws
- `InexactError`: if `m` or `n` is negative.
- `LibsemigroupsError`: if `m == 0`.
- `LibsemigroupsError`: if `n == 0`.
"""
function rectangular_band(m::Integer, n::Integer)
    mm = UInt(m)
    nn = UInt(n)
    native = @wrap_libsemigroups_call LibSemigroups.example_rectangular_band(mm, nn)
    return _wrap_presentation(native)
end

"""
    sigma_plactic_monoid(sigma::AbstractVector{<:Integer}) -> Presentation

Presentation for the ``\\sigma``-plactic monoid with coefficient sequence `sigma`.

This function returns a presentation for the ``\\sigma``-plactic monoid.
The image of ``\\sigma`` is given by the values in `sigma`, and the
resulting monoid is the quotient of the plactic monoid by the least
congruence containing the relations ``a^{\\sigma(a)} = a``.

!!! note "0-based `sigma`"
    Unlike alphabet letters (which are 1-based in the Julia API), the
    `sigma` argument here is a vector of libsemigroups-native 0-based
    coefficient indices - pass it through verbatim.

# Arguments
- `sigma::AbstractVector{<:Integer}`: the image of ``\\sigma`` in
  libsemigroups' native 0-based indexing.

# Throws
- `InexactError`: if any entry of `sigma` is negative.
- `LibsemigroupsError`: if `sigma` is empty.
"""
function sigma_plactic_monoid(sigma::AbstractVector{<:Integer})
    s = UInt[UInt(x) for x in sigma]
    native = @wrap_libsemigroups_call LibSemigroups.example_sigma_plactic_monoid(s)
    return _wrap_presentation(native)
end

"""
    renner_type_B_monoid(l::Integer, q::Integer) -> Presentation

A presentation for the Renner type B monoid of rank `l` over a field of size `q`.

This function returns a presentation for the Renner monoid of type B with
rank `l` and Iwahori-Hecke deformation `q`.

# Arguments
- `l::Integer`: the rank.
- `q::Integer`: the Iwahori-Hecke deformation.

# Throws
- `InexactError`: if `l` is negative, or if `q` is not representable as
  `Int32`.
- `LibsemigroupsError`: if `q` is neither `0` nor `1`.
"""
function renner_type_B_monoid(l::Integer, q::Integer)
    ll = UInt(l)
    qq = Int32(q)
    native = @wrap_libsemigroups_call LibSemigroups.example_renner_type_B_monoid(ll, qq)
    return _wrap_presentation(native)
end

"""
    renner_type_D_monoid(l::Integer, q::Integer) -> Presentation

A presentation for the Renner type D monoid of rank `l` over a field of size `q`.

This function returns a presentation for the Renner monoid of type D with
rank `l` and Iwahori-Hecke deformation `q`.

# Arguments
- `l::Integer`: the rank.
- `q::Integer`: the Iwahori-Hecke deformation.

# Throws
- `InexactError`: if `l` is negative, or if `q` is not representable as
  `Int32`.
- `LibsemigroupsError`: if `q` is neither `0` nor `1`.
"""
function renner_type_D_monoid(l::Integer, q::Integer)
    ll = UInt(l)
    qq = Int32(q)
    native = @wrap_libsemigroups_call LibSemigroups.example_renner_type_D_monoid(ll, qq)
    return _wrap_presentation(native)
end

"""
    not_renner_type_B_monoid(l::Integer, q::Integer) -> Presentation

A presentation (not Renner type B) related to the Renner type B monoid of
rank `l` over a field of size `q`.

This function returns a presentation that incorrectly claims to define
the Renner monoid of type B with rank `l` and Iwahori-Hecke deformation
`q`.

# Arguments
- `l::Integer`: the rank.
- `q::Integer`: the Iwahori-Hecke deformation.

# Throws
- `InexactError`: if `l` is negative, or if `q` is not representable as
  `Int32`.
- `LibsemigroupsError`: if `q` is neither `0` nor `1`.
"""
function not_renner_type_B_monoid(l::Integer, q::Integer)
    ll = UInt(l)
    qq = Int32(q)
    native = @wrap_libsemigroups_call LibSemigroups.example_not_renner_type_B_monoid(ll, qq)
    return _wrap_presentation(native)
end

"""
    not_renner_type_D_monoid(l::Integer, q::Integer) -> Presentation

A presentation (not Renner type D) related to the Renner type D monoid of
rank `l` over a field of size `q`.

This function returns a presentation that incorrectly claims to define
the Renner monoid of type D with rank `l` and Iwahori-Hecke deformation
`q`.

# Arguments
- `l::Integer`: the rank.
- `q::Integer`: the Iwahori-Hecke deformation.

# Throws
- `InexactError`: if `l` is negative, or if `q` is not representable as
  `Int32`.
- `LibsemigroupsError`: if `q` is neither `0` nor `1`.
"""
function not_renner_type_D_monoid(l::Integer, q::Integer)
    ll = UInt(l)
    qq = Int32(q)
    native = @wrap_libsemigroups_call LibSemigroups.example_not_renner_type_D_monoid(ll, qq)
    return _wrap_presentation(native)
end
