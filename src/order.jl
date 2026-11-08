# Copyright (c) 2026, James W. Swent
#
# Distributed under the terms of the GPL license version 3.

"""
order.jl - Order enum and compare helpers

Exposes `Order` (an enum selecting a word ordering - shortlex, lex, recursive-
path) along with comparator free functions instantiated for Julia
`Vector{Int}` words. The Julia public API uses 1-based letter indices; the
private `_word_to_cpp` helper converts to 0-based at the C++ boundary.
"""

# ============================================================================
# Enum type + value constants
# ============================================================================

"""
    Order

Enum type selecting a word ordering.

The values of this enum can be passed as the argument to functions such as
[`set_order!`](@ref) to specify which ordering should be used. The normal forms
for congruence classes are given with respect to one of these orders.

Values:
- [`ORDER_NONE`](@ref)        - no ordering
- [`ORDER_SHORTLEX`](@ref)    - short-lex: order by length, then lexicographically
- [`ORDER_LEX`](@ref)         - pure lexicographic (not a well-order in general)
- [`ORDER_RECURSIVE`](@ref)   - recursive-path ordering (Jantzen 2012,
  Definition 1.2.14, page 24)
"""
const Order = LibSemigroups.Order

"""
    ORDER_NONE

[`Order`](@ref) value representing no ordering.
"""
const ORDER_NONE = LibSemigroups.order_none

"""
    ORDER_SHORTLEX

[`Order`](@ref) value representing the short-lex ordering: words are first
ordered by length, then lexicographically among words of the same length.
"""
const ORDER_SHORTLEX = LibSemigroups.order_shortlex

"""
    ORDER_LEX

[`Order`](@ref) value representing the lexicographic ordering.

Note that this is not a well-order in general, so there may not be a
lexicographically least word in a given congruence class of words.
"""
const ORDER_LEX = LibSemigroups.order_lex

"""
    ORDER_RECURSIVE

[`Order`](@ref) value representing the recursive-path ordering, as described in
Jantzen 2012 (Definition 1.2.14, page 24).
"""
const ORDER_RECURSIVE = LibSemigroups.order_recursive

# ============================================================================
# Index-convention helpers (shared with word-range.jl, word-graph.jl, paths.jl)
# ----------------------------------------------------------------------------
# Julia uses 1-based letter indices; libsemigroups stores 0-based in
# `word_type = std::vector<size_t>` (UInt64 on 64-bit systems). Conversion
# is applied at the C++ boundary - these helpers are the only place the
# shift happens.
# ============================================================================


# ============================================================================
# Compare free functions
# ----------------------------------------------------------------------------
# All take Julia words (Vector{Int} with 1-based letter indices) and return
# Bool indicating `x < y` under the chosen ordering.
# ============================================================================

"""
    lex_less(x::AbstractVector{<:Integer}, y::AbstractVector{<:Integer}) -> Bool

Compare two words using pure lexicographic order.

Returns `true` if `x` is lexicographically less than `y`, and `false` otherwise.
The prefix relation applies: the empty word is less than any non-empty word,
and a proper prefix of `y` is less than `y`.

# Arguments
- `x::AbstractVector{<:Integer}`: the first word.
- `y::AbstractVector{<:Integer}`: the second word.

# Example
```jldoctest
julia> using Semigroups

julia> lex_less([1, 2], [2])
true

julia> lex_less([1, 1], [1, 2])
true
```
"""
lex_less(x::AbstractVector{<:Integer}, y::AbstractVector{<:Integer}) =
    LibSemigroups.lexicographical_compare(_word_to_cpp(x), _word_to_cpp(y))

"""
    shortlex_less(x::AbstractVector{<:Integer}, y::AbstractVector{<:Integer}) -> Bool

Compare two words using short-lex order.

Returns `true` if `x` precedes `y` in short-lex order: shorter words come first,
with ties broken lexicographically among words of the same length.

# Arguments
- `x::AbstractVector{<:Integer}`: the first word.
- `y::AbstractVector{<:Integer}`: the second word.
"""
shortlex_less(x::AbstractVector{<:Integer}, y::AbstractVector{<:Integer}) =
    LibSemigroups.shortlex_compare(_word_to_cpp(x), _word_to_cpp(y))

"""
    recursive_path_less(x::AbstractVector{<:Integer}, y::AbstractVector{<:Integer}) -> Bool

Compare two words using the recursive-path ordering.

Returns `true` if `x` precedes `y` under the recursive-path order (Jantzen 2012,
Definition 1.2.14, page 24). This is a well-order on any finite alphabet.

# Arguments
- `x::AbstractVector{<:Integer}`: the first word.
- `y::AbstractVector{<:Integer}`: the second word.
"""
recursive_path_less(x::AbstractVector{<:Integer}, y::AbstractVector{<:Integer}) =
    LibSemigroups.recursive_path_compare(_word_to_cpp(x), _word_to_cpp(y))

"""
    weighted_shortlex_less(x::AbstractVector{<:Integer},
                           y::AbstractVector{<:Integer},
                           weights::AbstractVector{<:Integer}) -> Bool

Compare two words under weighted short-lex.

Returns `true` if `x` precedes `y` when words are ordered first by the sum of
their letter weights, then lexicographically among words with the same total
weight.

`weights[i]` is the weight of letter `i` (1-based). `weights` must have at
least as many entries as the largest letter appearing in `x` or `y`.

# Arguments
- `x::AbstractVector{<:Integer}`: the first word.
- `y::AbstractVector{<:Integer}`: the second word.
- `weights::AbstractVector{<:Integer}`: the per-letter weights (1-based).
"""
weighted_shortlex_less(
    x::AbstractVector{<:Integer},
    y::AbstractVector{<:Integer},
    weights::AbstractVector{<:Integer},
) = LibSemigroups.wt_shortlex_compare(
    _word_to_cpp(x),
    _word_to_cpp(y),
    UInt[UInt(w) for w in weights],
)

"""
    weighted_lex_less(x::AbstractVector{<:Integer},
                      y::AbstractVector{<:Integer},
                      weights::AbstractVector{<:Integer}) -> Bool

Compare two words under weighted lex.

Returns `true` if `x` precedes `y` under weighted lex: letter weights determine
the comparison at each position rather than the letter index itself.

`weights[i]` is the weight of letter `i` (1-based). `weights` must have at
least as many entries as the largest letter appearing in `x` or `y`.

# Arguments
- `x::AbstractVector{<:Integer}`: the first word.
- `y::AbstractVector{<:Integer}`: the second word.
- `weights::AbstractVector{<:Integer}`: the per-letter weights (1-based).
"""
weighted_lex_less(
    x::AbstractVector{<:Integer},
    y::AbstractVector{<:Integer},
    weights::AbstractVector{<:Integer},
) = LibSemigroups.wt_lex_compare(
    _word_to_cpp(x),
    _word_to_cpp(y),
    UInt[UInt(w) for w in weights],
)
