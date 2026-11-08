# Copyright (c) 2026, James W. Swent
#
# Distributed under the terms of the GPL license version 3.

"""
todd-coxeter.jl - ToddCoxeter wrapper (Layer 2 + 3)
"""

# ============================================================================
# Type alias and enum constants
# ============================================================================

"""
    ToddCoxeter

Type implementing the Todd-Coxeter algorithm for computing 1- and 2-sided
congruences on finitely presented semigroups and monoids.

A `ToddCoxeter` object represents a coset enumeration over a presentation,
producing a [`WordGraph`](@ref Semigroups.WordGraph) whose nodes correspond
to the congruence classes. It is constructed from a
[`congruence_kind`](@ref Semigroups.congruence_kind) and a
[`Presentation`](@ref Semigroups.Presentation), or from another
`ToddCoxeter` (a quotient construction), or from a `WordGraph`.

`ToddCoxeter` is a subtype of [`CongruenceCommon`](@ref
Semigroups.CongruenceCommon) (and hence of [`Runner`](@ref Semigroups.Runner)),
so all runner methods (`run!`, `run_for!`, `run_until!`, `finished`,
`timed_out`, `current_state`, etc.) and all common congruence helpers
(`reduce`, `contains`, `currently_contains`, `add_generating_pair!`,
`normal_forms`, `partition`, `non_trivial_classes`) work on `ToddCoxeter`
objects.

# Constructors

    ToddCoxeter(kind::congruence_kind, p::Presentation) -> ToddCoxeter
    ToddCoxeter(kind::congruence_kind, tc::ToddCoxeter) -> ToddCoxeter
    ToddCoxeter(kind::congruence_kind, wg::WordGraph) -> ToddCoxeter
    ToddCoxeter(other::ToddCoxeter) -> ToddCoxeter

# Throws

- `LibsemigroupsError` if `p` is not valid (Presentation form).
- `LibsemigroupsError` if `kind` and `tc.kind()` are incompatible
  (ToddCoxeter form). Compatible pairs `(tc.kind(), kind)` are
  `(onesided, onesided)`, `(twosided, onesided)`, and `(twosided, twosided)`.

Words use the representation of the input presentation: integer vectors or ASCII strings.
"""
struct ToddCoxeter{W,B} <: CongruenceCommon{W}
    cxx_obj::B
end

_native_algorithm(::Type{ToddCoxeter}, ::Type{Vector{Int}}) = LibSemigroups.ToddCoxeterWord
_native_algorithm(::Type{ToddCoxeter}, ::Type{String}) = LibSemigroups.ToddCoxeterString
_wrap_todd_coxeter(x::LibSemigroups.ToddCoxeterWord) = ToddCoxeter{Vector{Int},typeof(x)}(x)
_wrap_todd_coxeter(x::LibSemigroups.ToddCoxeterString) = ToddCoxeter{String,typeof(x)}(x)
ToddCoxeter{W}() where {W} = _wrap_todd_coxeter(_native_algorithm(ToddCoxeter, W)())
ToddCoxeter() = ToddCoxeter{Vector{Int}}()
ToddCoxeter(other::ToddCoxeter{W}) where {W} = _wrap_todd_coxeter(
    @wrap_libsemigroups_call _native_algorithm(ToddCoxeter, W)(_native(other))
)

ToddCoxeter(kind::congruence_kind, p::Presentation{W}) where {W} =
    init!(ToddCoxeter{W}(), kind, p)


# --- strategy ---------------------------------------------------------------

"""
    strategy_hlt

Strategy enum value: the HLT (Hazelgrove-Leech-Trotter) strategy. Analogous
to the [ACE](https://staff.itee.uq.edu.au/havas/) R-style strategy. See
[`strategy!`](@ref Semigroups.strategy!).
"""
const strategy_hlt = LibSemigroups.strategy_hlt

"""
    strategy_felsch

Strategy enum value: the Felsch strategy. Analogous to the
[ACE](https://staff.itee.uq.edu.au/havas/) C-style strategy. See
[`strategy!`](@ref Semigroups.strategy!).
"""
const strategy_felsch = LibSemigroups.strategy_felsch

"""
    strategy_CR

Strategy enum value: mimics the [ACE](https://staff.itee.uq.edu.au/havas/) CR
strategy. The Felsch strategy is run until at least `f_defs()` nodes are
defined, then HLT is run until at least `hlt_defs()/N` nodes have been defined
(where `N` is the sum of the lengths of the words in the presentation and
generating pairs); these steps are repeated until enumeration terminates. See
[`strategy!`](@ref Semigroups.strategy!).
"""
const strategy_CR = LibSemigroups.strategy_CR

"""
    strategy_R_over_C

Strategy enum value: mimics the [ACE](https://staff.itee.uq.edu.au/havas/) R/C
strategy. HLT runs until the first lookahead is triggered (when the number of
active nodes reaches `lookahead_next`); a full lookahead is then performed,
after which the [`strategy_CR`](@ref Semigroups.strategy_CR) strategy is used.
See [`strategy!`](@ref Semigroups.strategy!).
"""
const strategy_R_over_C = LibSemigroups.strategy_R_over_C

"""
    strategy_Cr

Strategy enum value: mimics the [ACE](https://staff.itee.uq.edu.au/havas/) Cr
strategy. Felsch runs until at least `f_defs()` new nodes have been defined,
HLT runs until at least `hlt_defs()/N` further nodes have been defined (`N`
as in [`strategy_CR`](@ref Semigroups.strategy_CR)), and finally Felsch runs
to completion. See [`strategy!`](@ref Semigroups.strategy!).
"""
const strategy_Cr = LibSemigroups.strategy_Cr

"""
    strategy_Rc

Strategy enum value: mimics the [ACE](https://staff.itee.uq.edu.au/havas/) Rc
strategy. HLT runs until at least `hlt_defs()/N` new nodes have been defined
(`N` as in [`strategy_CR`](@ref Semigroups.strategy_CR)), Felsch runs until
at least `f_defs()` further nodes have been defined, and finally HLT runs to
completion. See [`strategy!`](@ref Semigroups.strategy!).
"""
const strategy_Rc = LibSemigroups.strategy_Rc

# --- lookahead_extent -------------------------------------------------------

"""
    lookahead_extent_full

Lookahead-extent enum value: perform a full lookahead from every node in the
word graph. Full lookaheads are sometimes slower but may detect more
coincidences than a partial lookahead. See
[`lookahead_extent!`](@ref Semigroups.lookahead_extent!).
"""
const lookahead_extent_full = LibSemigroups.lookahead_extent_full

"""
    lookahead_extent_partial

Lookahead-extent enum value: perform a partial lookahead starting from the
current node in the word graph. Partial lookaheads are sometimes faster but
may not detect as many coincidences as a full lookahead. See
[`lookahead_extent!`](@ref Semigroups.lookahead_extent!).
"""
const lookahead_extent_partial = LibSemigroups.lookahead_extent_partial

# --- lookahead_style --------------------------------------------------------

"""
    lookahead_style_hlt

Lookahead-style enum value: HLT-style lookahead - follow the paths labelled by
every relation from every node in the range specified by the current
[`lookahead_extent`](@ref Semigroups.lookahead_extent). See
[`lookahead_style!`](@ref Semigroups.lookahead_style!).
"""
const lookahead_style_hlt = LibSemigroups.lookahead_style_hlt

"""
    lookahead_style_felsch

Lookahead-style enum value: Felsch-style lookahead - every edge is considered
in every path labelled by a relation in which it occurs. See
[`lookahead_style!`](@ref Semigroups.lookahead_style!).
"""
const lookahead_style_felsch = LibSemigroups.lookahead_style_felsch

# --- def_policy -------------------------------------------------------------

"""
    def_policy_no_stack_if_no_space

Definition-policy enum value: when the definition stack reaches the limit
`def_max`, newly generated definitions are dropped on the floor. See
[`def_policy!`](@ref Semigroups.def_policy!).
"""
const def_policy_no_stack_if_no_space = LibSemigroups.def_policy_no_stack_if_no_space

"""
    def_policy_purge_from_top

Definition-policy enum value: when the stack is full and a new definition is
generated, definitions whose source node is dead are popped from the top of
the stack. See [`def_policy!`](@ref Semigroups.def_policy!).
"""
const def_policy_purge_from_top = LibSemigroups.def_policy_purge_from_top

"""
    def_policy_purge_all

Definition-policy enum value: when the stack is full and a new definition is
generated, all definitions with a dead source node are removed from the
entire stack (not just the top). See [`def_policy!`](@ref Semigroups.def_policy!).
"""
const def_policy_purge_all = LibSemigroups.def_policy_purge_all

"""
    def_policy_discard_all_if_no_space

Definition-policy enum value: when the stack is full and a new definition is
generated, the entire definition stack is discarded. See
[`def_policy!`](@ref Semigroups.def_policy!).
"""
const def_policy_discard_all_if_no_space = LibSemigroups.def_policy_discard_all_if_no_space

"""
    def_policy_unlimited

Definition-policy enum value: place no limit on the number of stacked
definitions. See [`def_policy!`](@ref Semigroups.def_policy!).
"""
const def_policy_unlimited = LibSemigroups.def_policy_unlimited

# --- def_version ------------------------------------------------------------

"""
    def_version_one

Definition-version enum value: the simpler version of definition processing.
May follow the same dead-end path multiple times. See
[`def_version!`](@ref Semigroups.def_version!).
"""
const def_version_one = LibSemigroups.def_version_one

"""
    def_version_two

Definition-version enum value: the more complex version of definition
processing. Attempts to avoid re-following a path once it has been found to
lead nowhere. See [`def_version!`](@ref Semigroups.def_version!).
"""
const def_version_two = LibSemigroups.def_version_two

# ============================================================================
# Class-index conversion (private, file-local)
# ============================================================================
# C++ uses 0-based class indices and `typemax(size_t)` for UNDEFINED. These
# helpers translate at the Julia<->C++ boundary; keep their calls *outside*
# `@wrap_libsemigroups_call` so that native Julia errors (e.g., `InexactError`
# from `UInt(0 - 1)`) propagate as themselves rather than being re-wrapped.

@inline _index_to_cpp(i::Integer) = UInt(i - 1)
@inline _index_from_cpp(i::Integer) = i == typemax(UInt) ? UNDEFINED : Int(i) + 1

# ============================================================================
# Initialization
# ============================================================================

"""
    init!(tc::ToddCoxeter) -> ToddCoxeter
    init!(tc::ToddCoxeter, kind::congruence_kind, p::Presentation) -> ToddCoxeter
    init!(tc::ToddCoxeter, kind::congruence_kind, other::ToddCoxeter) -> ToddCoxeter
    init!(tc::ToddCoxeter, kind::congruence_kind, wg::WordGraph) -> ToddCoxeter

Re-initialize `tc` so that it is in the state it would have been in
immediately after the corresponding constructor.

The one-argument form clears the underlying word graph, presentation,
generating pairs, settings, and statistics, putting `tc` back into the same
state as a newly default-constructed
[`ToddCoxeter`](@ref Semigroups.ToddCoxeter).

The three-argument forms reinitialize `tc` from the corresponding arguments
- `(kind, p)` for a [`Presentation`](@ref Semigroups.Presentation),
`(kind, other)` for a quotient of another `ToddCoxeter`, or `(kind, wg)` for
a [`WordGraph`](@ref Semigroups.WordGraph).

Returns `tc` for chaining.

# Throws

- `LibsemigroupsError` if `p` is not valid (Presentation form).
- `LibsemigroupsError` if `kind` and `other.kind()` are incompatible
  (ToddCoxeter form). The compatible pairs `(other.kind(), kind)` are
  `(onesided, onesided)`, `(twosided, onesided)`, and `(twosided, twosided)`.
"""
function init!(tc::ToddCoxeter)
    @wrap_libsemigroups_call LibSemigroups.init!(_native(tc))
    return tc
end

function init!(tc::ToddCoxeter, kind::congruence_kind, p::Presentation)
    _require_same_word_type(tc, p)
    @wrap_libsemigroups_call LibSemigroups.init!(_native(tc), kind, _native(p))
    return tc
end

function init!(tc::ToddCoxeter, kind::congruence_kind, other::ToddCoxeter)
    _require_same_word_type(tc, other)
    @wrap_libsemigroups_call LibSemigroups.init!(_native(tc), kind, _native(other))
    return tc
end

function init!(tc::ToddCoxeter, kind::congruence_kind, wg::WordGraph)
    @wrap_libsemigroups_call LibSemigroups.init!(_native(tc), kind, wg)
    return tc
end

# ============================================================================
# Settings - getter / setter pairs
# ============================================================================

"""
    strategy(tc::ToddCoxeter)

Return the current coset enumeration strategy of `tc`.

The returned value is one of [`strategy_hlt`](@ref Semigroups.strategy_hlt)
(the default), [`strategy_felsch`](@ref Semigroups.strategy_felsch),
[`strategy_CR`](@ref Semigroups.strategy_CR),
[`strategy_R_over_C`](@ref Semigroups.strategy_R_over_C),
[`strategy_Cr`](@ref Semigroups.strategy_Cr), or
[`strategy_Rc`](@ref Semigroups.strategy_Rc).

# See also

[`strategy!`](@ref Semigroups.strategy!)
"""
strategy(tc::ToddCoxeter) = LibSemigroups.strategy(_native(tc))

"""
    strategy!(tc::ToddCoxeter, val) -> ToddCoxeter

Set the coset enumeration strategy of `tc` to `val`. Returns `tc` for
chaining. `val` must be one of the `strategy_*` enum constants.

# See also

[`strategy`](@ref Semigroups.strategy)
"""
function strategy!(tc::ToddCoxeter, val)
    LibSemigroups.set_strategy!(_native(tc), val)
    return tc
end

"""
    lookahead_extent(tc::ToddCoxeter)

Return the current lookahead extent of `tc`. The default is
[`lookahead_extent_partial`](@ref Semigroups.lookahead_extent_partial).

The returned value is one of
[`lookahead_extent_full`](@ref Semigroups.lookahead_extent_full) or
[`lookahead_extent_partial`](@ref Semigroups.lookahead_extent_partial).

# See also

[`lookahead_extent!`](@ref Semigroups.lookahead_extent!)
"""
lookahead_extent(tc::ToddCoxeter) = LibSemigroups.lookahead_extent(_native(tc))

"""
    lookahead_extent!(tc::ToddCoxeter, val) -> ToddCoxeter

Set the lookahead extent of `tc` to `val`. Returns `tc` for chaining.

# See also

[`lookahead_extent`](@ref Semigroups.lookahead_extent)
"""
function lookahead_extent!(tc::ToddCoxeter, val)
    LibSemigroups.set_lookahead_extent!(_native(tc), val)
    return tc
end

"""
    lookahead_style(tc::ToddCoxeter)

Return the current lookahead style of `tc`. The default is
[`lookahead_style_hlt`](@ref Semigroups.lookahead_style_hlt).

The returned value is one of
[`lookahead_style_hlt`](@ref Semigroups.lookahead_style_hlt) or
[`lookahead_style_felsch`](@ref Semigroups.lookahead_style_felsch).

# See also

[`lookahead_style!`](@ref Semigroups.lookahead_style!)
"""
lookahead_style(tc::ToddCoxeter) = LibSemigroups.lookahead_style(_native(tc))

"""
    lookahead_style!(tc::ToddCoxeter, val) -> ToddCoxeter

Set the lookahead style of `tc` to `val`. Returns `tc` for chaining.

# See also

[`lookahead_style`](@ref Semigroups.lookahead_style)
"""
function lookahead_style!(tc::ToddCoxeter, val)
    LibSemigroups.set_lookahead_style!(_native(tc), val)
    return tc
end

"""
    save(tc::ToddCoxeter) -> Bool

Return whether definitions are processed during HLT-style enumeration. The
default is `false`.

# See also

[`save!`](@ref Semigroups.save!)
"""
save(tc::ToddCoxeter) = LibSemigroups.save(_native(tc))

"""
    save!(tc::ToddCoxeter, val::Bool) -> ToddCoxeter

Set whether definitions are processed during any HLT-style enumeration of
`tc`. Returns `tc` for chaining. The default is `false`.

If `val` is `true` and the HLT strategy is in use, definitions are processed
during enumeration. This typically slows HLT down but can reduce the size of
the underlying word graph.

# See also

[`save`](@ref Semigroups.save)
"""
function save!(tc::ToddCoxeter, val::Bool)
    LibSemigroups.set_save!(_native(tc), val)
    return tc
end

"""
    use_relations_in_extra(tc::ToddCoxeter) -> Bool

Return whether, when the Felsch strategy is in use over a finitely presented
semigroup or monoid, the algorithm performs an HLT-style push of the defining
relations at the identity. The default is `false`.

# See also

[`use_relations_in_extra!`](@ref Semigroups.use_relations_in_extra!)
"""
use_relations_in_extra(tc::ToddCoxeter) = LibSemigroups.use_relations_in_extra(_native(tc))

"""
    use_relations_in_extra!(tc::ToddCoxeter, val::Bool) -> ToddCoxeter

Set whether, when the Felsch strategy is in use over a finitely presented
semigroup or monoid, the algorithm should follow all paths from the identity
labelled by the underlying relations. Returns `tc` for chaining. The default
is `false`.

# See also

[`use_relations_in_extra`](@ref Semigroups.use_relations_in_extra)
"""
function use_relations_in_extra!(tc::ToddCoxeter, val::Bool)
    LibSemigroups.set_use_relations_in_extra!(_native(tc), val)
    return tc
end

"""
    lower_bound(tc::ToddCoxeter) -> Union{Int, UndefinedType}

Return the current lower bound on the number of classes of the congruence
represented by `tc`. The default is [`UNDEFINED`](@ref Semigroups.UNDEFINED)
(no bound set); otherwise an `Int`.

# See also

[`lower_bound!`](@ref Semigroups.lower_bound!)
"""
function lower_bound(tc::ToddCoxeter)
    val = LibSemigroups.lower_bound(_native(tc))
    return val == typemax(UInt) ? UNDEFINED : Int(val)
end

"""
    lower_bound!(tc::ToddCoxeter, val::Integer) -> ToddCoxeter
    lower_bound!(tc::ToddCoxeter, ::UndefinedType) -> ToddCoxeter

Set a lower bound on the number of classes of the congruence represented by
`tc`. Returns `tc` for chaining.

If the number of active nodes during enumeration reaches `val` and the word
graph is complete, the algorithm may stop early. When the bound equals the
number of classes, this can avoid following relation-labelled paths at many
nodes once no further coincidences are possible. Pass
[`UNDEFINED`](@ref Semigroups.UNDEFINED) to clear the bound (the default).

# See also

[`lower_bound`](@ref Semigroups.lower_bound)
"""
function lower_bound!(tc::ToddCoxeter, val::Integer)
    LibSemigroups.set_lower_bound!(_native(tc), UInt(val))
    return tc
end

lower_bound!(tc::ToddCoxeter, ::UndefinedType) =
    (LibSemigroups.set_lower_bound!(_native(tc), typemax(UInt)); tc)

"""
    def_version(tc::ToddCoxeter)

Return the current definition-routine version of `tc`. The default is
[`def_version_two`](@ref Semigroups.def_version_two).

The returned value is one of
[`def_version_one`](@ref Semigroups.def_version_one) or
[`def_version_two`](@ref Semigroups.def_version_two).

# See also

[`def_version!`](@ref Semigroups.def_version!)
"""
def_version(tc::ToddCoxeter) = LibSemigroups.def_version(_native(tc))

"""
    def_version!(tc::ToddCoxeter, val) -> ToddCoxeter

Set the definition-routine version of `tc` to `val`. Returns `tc` for
chaining.

# See also

[`def_version`](@ref Semigroups.def_version)
"""
function def_version!(tc::ToddCoxeter, val)
    LibSemigroups.set_def_version!(_native(tc), val)
    return tc
end

"""
    def_policy(tc::ToddCoxeter)

Return the current definition-stack policy of `tc`. The default is
[`def_policy_no_stack_if_no_space`](@ref Semigroups.def_policy_no_stack_if_no_space).
Together with `def_max` (currently not bound) the policy controls what
happens when the stack of pending definitions becomes full.

The returned value is one of
[`def_policy_no_stack_if_no_space`](@ref Semigroups.def_policy_no_stack_if_no_space),
[`def_policy_purge_from_top`](@ref Semigroups.def_policy_purge_from_top),
[`def_policy_purge_all`](@ref Semigroups.def_policy_purge_all),
[`def_policy_discard_all_if_no_space`](@ref Semigroups.def_policy_discard_all_if_no_space),
or [`def_policy_unlimited`](@ref Semigroups.def_policy_unlimited).

# See also

[`def_policy!`](@ref Semigroups.def_policy!)
"""
def_policy(tc::ToddCoxeter) = LibSemigroups.def_policy(_native(tc))

"""
    def_policy!(tc::ToddCoxeter, val) -> ToddCoxeter

Set the definition-stack policy of `tc` to `val`. Returns `tc` for
chaining.

# See also

[`def_policy`](@ref Semigroups.def_policy)
"""
function def_policy!(tc::ToddCoxeter, val)
    LibSemigroups.set_def_policy!(_native(tc), val)
    return tc
end

# ============================================================================
# Standardize / word-graph access
# ============================================================================

"""
    standardize!(tc::ToddCoxeter, ord::Order) -> Bool

Standardize the [`current_word_graph`](@ref Semigroups.current_word_graph) of
`tc` with respect to the order `ord`. This function does **not** trigger any
enumeration.

Returns `true` if the word graph was modified - equivalently, if it was not
already standardized with respect to `ord` - and `false` otherwise.

# Arguments

- `tc::ToddCoxeter`: the `ToddCoxeter` instance to standardize.
- `ord::Order`: the order to standardize by - typically
  [`ORDER_SHORTLEX`](@ref Semigroups.ORDER_SHORTLEX) or
  [`ORDER_LEX`](@ref Semigroups.ORDER_LEX).

# See also

[`is_standardized`](@ref Semigroups.is_standardized)
"""
function standardize!(tc::ToddCoxeter, ord::Order)
    return @wrap_libsemigroups_call LibSemigroups.standardize!(_native(tc), ord)
end

"""
    is_standardized(tc::ToddCoxeter) -> Bool
    is_standardized(tc::ToddCoxeter, ord::Order) -> Bool

Return whether the [`current_word_graph`](@ref Semigroups.current_word_graph)
of `tc` is standardized.

The one-argument form returns `true` if the word graph has been standardized
with respect to any [`Order`](@ref Semigroups.Order) other than
[`ORDER_NONE`](@ref Semigroups.ORDER_NONE). The two-argument form returns
`true` only if it has been standardized with respect to `ord`.

!!! warning "Deprecated upstream"
    The corresponding libsemigroups members are marked deprecated; they
    suggest using `current_word_graph(tc).is_standardized(...)` directly. The
    Julia binding still exposes both forms so existing code continues to
    compile, but new code should prefer the word-graph form.

# See also

[`standardize!`](@ref Semigroups.standardize!)
"""
is_standardized(tc::ToddCoxeter) = LibSemigroups.is_standardized(_native(tc))

is_standardized(tc::ToddCoxeter, ord::Order) =
    LibSemigroups.is_standardized(_native(tc), ord)

"""
    current_word_graph(tc::ToddCoxeter) -> WordGraph

Return an owning snapshot of the word graph of `tc` in its current state,
without triggering an enumeration. The copy remains valid after `tc` changes.

The returned graph may be in a complicated state: nothing is guaranteed about
the labels of active nodes (they may be any non-negative integers in any
order), about whether the active node count matches the total node count,
about completeness, or about compatibility with the relations of
[`presentation`](@ref Semigroups.presentation) or with
[`generating_pairs`](@ref Semigroups.generating_pairs). Use
[`standardize!`](@ref Semigroups.standardize!) (or `shrink_to_fit`, not yet
bound) to put it into a more reasonable state.

# See also

[`word_graph`](@ref Semigroups.word_graph)
"""
current_word_graph(tc::ToddCoxeter) =
    @wrap_libsemigroups_call LibSemigroups.current_word_graph(_native(tc))

"""
    word_graph(tc::ToddCoxeter) -> WordGraph

Return an owning snapshot of the word graph of `tc` after triggering a full
enumeration. The copy remains valid after `tc` is changed or released. The returned graph is short-lex standardized: its active nodes
are exactly `0, ..., n-1` where `n` is
[`number_of_classes`](@ref Semigroups.number_of_classes) (or `n+1` when the
underlying [`presentation`](@ref Semigroups.presentation) does not contain
the empty word). It will usually be complete and compatible with the
relations of `presentation` and with `generating_pairs`, though some
combinations of settings (e.g. an aggressive
[`lower_bound!`](@ref Semigroups.lower_bound!)) can break this.

!!! warning
    This function may never terminate if the congruence is undecidable.

# See also

[`current_word_graph`](@ref Semigroups.current_word_graph)
"""
word_graph(tc::ToddCoxeter) = @wrap_libsemigroups_call LibSemigroups.word_graph(_native(tc))

# ============================================================================
# Word <-> class index conversions
# ============================================================================

"""
    index_of(tc::ToddCoxeter, w::AbstractVector{<:Integer}) -> Int

Return the 1-based index of the congruence class containing `w`, triggering
a full enumeration of `tc`.

If [`current_word_graph`](@ref Semigroups.current_word_graph) is not already
standardized, the algorithm first standardizes it with respect to short-lex
order; otherwise the existing standardization is preserved. Because
enumeration completes, the result is never
[`UNDEFINED`](@ref Semigroups.UNDEFINED).

# Arguments

- `tc::ToddCoxeter`: the `ToddCoxeter` instance.
- `w::AbstractVector{<:Integer}`: a 1-based `Vector{Int}` of letter
  indices.

# Throws

- `LibsemigroupsError` if any letter in `w` is not in the alphabet of the
  underlying presentation.

!!! warning
    This function may never terminate if the congruence is undecidable.

# See also

[`current_index_of`](@ref Semigroups.current_index_of),
[`word_of`](@ref Semigroups.word_of)
"""
function index_of(tc::ToddCoxeter, w::Union{AbstractVector{<:Integer},AbstractString})
    cpp_w = _word_to_cpp(_word_type(tc), w)
    cpp_i = @wrap_libsemigroups_call LibSemigroups.index_of(_native(tc), cpp_w)
    return _index_from_cpp(cpp_i)
end

"""
    current_index_of(tc::ToddCoxeter, w::AbstractVector{<:Integer}) -> Union{Int, UndefinedType}

Return the 1-based index of the congruence class containing `w` if it is
already known, without triggering a run.

If the class of `w` is not currently known, returns
[`UNDEFINED`](@ref Semigroups.UNDEFINED). Test for that case with
`result === UNDEFINED` (or [`is_undefined`](@ref Semigroups.is_undefined));
`result == typemax(UInt)` will always be `false` because `UNDEFINED` is
its own singleton type.

# Arguments

- `tc::ToddCoxeter`: the `ToddCoxeter` instance.
- `w::AbstractVector{<:Integer}`: a 1-based `Vector{Int}` of letter
  indices.

# Throws

- `LibsemigroupsError` if any letter in `w` is not in the alphabet of the
  underlying presentation.

# See also

[`index_of`](@ref Semigroups.index_of),
[`current_word_of`](@ref Semigroups.current_word_of)
"""
function current_index_of(
    tc::ToddCoxeter,
    w::Union{AbstractVector{<:Integer},AbstractString},
)
    cpp_w = _word_to_cpp(_word_type(tc), w)
    cpp_i = @wrap_libsemigroups_call LibSemigroups.current_index_of(_native(tc), cpp_w)
    return _index_from_cpp(cpp_i)
end

"""
    word_of(tc::ToddCoxeter, i::Integer) -> Vector{Int}

Return a representative word for the `i`-th congruence class of `tc`
(1-based).

This function triggers a full enumeration of `tc`, which may never
terminate.

# Arguments

- `tc::ToddCoxeter`: the `ToddCoxeter` instance.
- `i::Integer`: a 1-based class index.

# Throws

- `LibsemigroupsError` if `i` is out of range.

# See also

[`current_word_of`](@ref Semigroups.current_word_of),
[`index_of`](@ref Semigroups.index_of)
"""
function word_of(tc::ToddCoxeter, i::Integer)
    cpp_i = _index_to_cpp(i)
    out = @wrap_libsemigroups_call LibSemigroups.word_of(_native(tc), cpp_i)
    return _word_from_cpp(_word_type(tc), out)
end

"""
    current_word_of(tc::ToddCoxeter, i::Integer) -> Vector{Int}

Return a representative word for the `i`-th congruence class of `tc`
(1-based), without triggering an enumeration.

If [`current_word_graph`](@ref Semigroups.current_word_graph) is not already
standardized, this function standardizes it with respect to short-lex order
as a side effect. The returned word is obtained by walking the
current-spanning-tree path from the node corresponding to class `i` back to
the root.

# Arguments

- `tc::ToddCoxeter`: the `ToddCoxeter` instance.
- `i::Integer`: a 1-based class index.

# Throws

- `LibsemigroupsError` if `i` is out of range relative to the current
  state of `tc`.

# See also

[`word_of`](@ref Semigroups.word_of),
[`current_index_of`](@ref Semigroups.current_index_of)
"""
function current_word_of(tc::ToddCoxeter, i::Integer)
    cpp_i = _index_to_cpp(i)
    out = @wrap_libsemigroups_call LibSemigroups.current_word_of(_native(tc), cpp_i)
    return _word_from_cpp(_word_type(tc), out)
end

"""
    throw_if_letter_not_in_alphabet(tc::ToddCoxeter, w::AbstractVector{<:Integer})

Check that every letter in `w` belongs to the alphabet of the underlying
presentation of `tc`.

# Arguments

- `tc::ToddCoxeter`: the `ToddCoxeter` instance.
- `w::AbstractVector{<:Integer}`: a 1-based `Vector{Int}` of letter indices.

# Throws

- `LibsemigroupsError` if any letter in `w` is not in the alphabet of the
  underlying presentation.
"""
function throw_if_letter_not_in_alphabet(
    tc::ToddCoxeter,
    w::Union{AbstractVector{<:Integer},AbstractString},
)
    cpp_w = _word_to_cpp(_word_type(tc), w)
    @wrap_libsemigroups_call LibSemigroups.throw_if_letter_not_in_alphabet(
        _native(tc),
        cpp_w,
    )
    return nothing
end

# ============================================================================
# Query methods
# ============================================================================

"""
    number_of_classes(tc::ToddCoxeter) -> UInt64

Compute the number of congruence classes, triggering a full run if
needed.

Returns [`POSITIVE_INFINITY`](@ref Semigroups.POSITIVE_INFINITY) if the
congruence has infinitely many classes.

The return type is `UInt64` (rather than `Int`, which is the project
convention elsewhere) because `POSITIVE_INFINITY` is encoded as
`typemax(UInt64)` on the wire and would not round-trip through `Int`.
Use [`is_positive_infinity`](@ref Semigroups.is_positive_infinity) to
detect the infinite case.

!!! warning
    This function may not terminate if the congruence has infinitely many
    classes and the algorithm cannot detect this.
"""
number_of_classes(tc::ToddCoxeter) =
    @wrap_libsemigroups_call LibSemigroups.number_of_classes(_native(tc))

"""
    kind(tc::ToddCoxeter) -> congruence_kind

Return the kind (1- or 2-sided) of the congruence represented by `tc`.
The result is either [`twosided`](@ref Semigroups.twosided) or
[`onesided`](@ref Semigroups.onesided); see
[`congruence_kind`](@ref Semigroups.congruence_kind).
"""
kind(tc::ToddCoxeter) = LibSemigroups.kind(_native(tc))

"""
    number_of_generating_pairs(tc::ToddCoxeter) -> Int

Return the number of generating pairs added to `tc`.

This equals the length of [`generating_pairs`](@ref
Semigroups.generating_pairs).
"""
number_of_generating_pairs(tc::ToddCoxeter) =
    Int(LibSemigroups.number_of_generating_pairs(_native(tc)))

"""
    generating_pairs(tc::ToddCoxeter) -> Vector{Tuple{Vector{Int}, Vector{Int}}}

Return the generating pairs of `tc` as a vector of 1-based word pairs.

These are the pairs added via
[`add_generating_pair!`](@ref Semigroups.add_generating_pair!). Words are
returned as 1-based `Vector{Int}` letter indices. The length of the returned
vector equals
[`number_of_generating_pairs`](@ref Semigroups.number_of_generating_pairs).
"""
function generating_pairs(tc::ToddCoxeter)
    flat = LibSemigroups.generating_pairs(_native(tc))
    return _word_pairs_from_cpp(_word_type(tc), flat)
end

"""
    presentation(tc::ToddCoxeter) -> Presentation

Return a copy of the presentation used to construct `tc`.

If `tc` was constructed or initialised from a
[`WordGraph`](@ref Semigroups.WordGraph) rather than a
[`Presentation`](@ref Semigroups.Presentation), the returned presentation is
empty.
"""
presentation(tc::ToddCoxeter) = _wrap_presentation(LibSemigroups.presentation(_native(tc)))

# ============================================================================
# Base.* overloads
# ============================================================================

"""
    Base.length(tc::ToddCoxeter) -> UInt64

Return the number of congruence classes. Equivalent to
[`number_of_classes`](@ref Semigroups.number_of_classes).
"""
Base.length(tc::ToddCoxeter) = number_of_classes(tc)

"""
    Base.show(io::IO, tc::ToddCoxeter)

Print a human-readable representation of `tc`.
"""
function Base.show(io::IO, tc::ToddCoxeter)
    print(io, LibSemigroups.to_human_readable_repr(_native(tc)))
end

"""
    Base.copy(tc::ToddCoxeter) -> ToddCoxeter

Create an independent copy of `tc`.
"""
Base.copy(tc::ToddCoxeter) = ToddCoxeter(tc)

Base.deepcopy_internal(tc::ToddCoxeter, ::IdDict) = ToddCoxeter(tc)

# ============================================================================
# Free functions (todd_coxeter:: namespace)
# ============================================================================

"""
    is_non_trivial(tc::ToddCoxeter;
                   tries::Integer = 10,
                   try_for::TimePeriod = Dates.Millisecond(100),
                   threshold::Real = 0.99) -> tril

Heuristically check whether the congruence represented by `tc` is
non-trivial.

Repeatedly runs the algorithm for at most `try_for` time, with a random
subset of the generating pairs removed, up to `tries` times. If the ratio
of the number of classes in the modified system to the number in `tc` is
at most `threshold`, the function returns [`tril_TRUE`](@ref
Semigroups.tril_TRUE) (the congruence is likely non-trivial). If after
`tries` attempts no such ratio is observed, returns
[`tril_FALSE`](@ref Semigroups.tril_FALSE). Returns
[`tril_unknown`](@ref Semigroups.tril_unknown) if the function cannot
decide.

# Arguments

- `tc::ToddCoxeter`: the `ToddCoxeter` instance to check.
- `tries::Integer`: number of attempts (default `10`).
- `try_for::TimePeriod`: time budget per attempt (default
  `Millisecond(100)`).
- `threshold::Real`: ratio threshold (default `0.99`).

!!! note
    The libsemigroups helper takes `std::chrono::milliseconds` internally;
    the C++ binding receives nanoseconds and casts down, truncating
    sub-millisecond values to zero. The default of `Millisecond(100)` is
    safely above this precision boundary.
"""
function is_non_trivial(
    tc::ToddCoxeter;
    tries::Integer = 10,
    try_for::TimePeriod = Dates.Millisecond(100),
    threshold::Real = 0.99,
)
    # Coerce all arguments outside `@wrap_libsemigroups_call` so a Julia-side
    # InexactError (e.g. negative `tries`) propagates as itself instead of
    # being re-wrapped as `LibsemigroupsError` by the macro's broad catch.
    ut = UInt(tries)
    ns = Int64(Dates.value(convert(Nanosecond, try_for)))
    th = Float32(threshold)
    return @wrap_libsemigroups_call LibSemigroups.tc_is_non_trivial(_native(tc), ut, ns, th)
end

"""
    tc_redundant_rule(p::Presentation, timeout::TimePeriod) -> Union{Int, Nothing}

Find a redundant rule in `p` using the Todd-Coxeter algorithm, with the
given timeout.

Starting with the last rule in `p`, this function attempts to run
Todd-Coxeter on the rules of `p` with each rule omitted in turn. For each
omitted rule, Todd-Coxeter is run for at most `timeout`, then it checks
whether the omitted rule follows from the remaining rules. Returns the
1-based rule-pair index of the first redundant rule found, or `nothing`
if no redundant rule is identified within the timeout.

!!! warning
    This function is non-deterministic: results may differ between calls
    with identical parameters.

# Arguments

- `p::Presentation`: the presentation to search.
- `timeout::TimePeriod`: maximum time per omitted rule (e.g.
  `Millisecond(100)`, `Second(5)`).

# See also

[`redundant_rule`](@ref Semigroups.redundant_rule) - the analogous
Knuth-Bendix-based helper.
"""
function tc_redundant_rule(p::Presentation, timeout::TimePeriod)
    # See note on is_non_trivial: keep coercions out of the macro arglist.
    ns = Int64(Dates.value(convert(Nanosecond, timeout)))
    idx = @wrap_libsemigroups_call LibSemigroups.tc_redundant_rule(_native(p), ns)
    n_flat = 2 * number_of_rules(p)
    if idx >= n_flat
        return nothing
    end
    # Convert from 0-based flat index (lhs position, always even) to
    # 1-based rule-pair index. C++ contract guarantees lhs position.
    return div(Int(idx), 2) + 1
end

ToddCoxeter(kind::congruence_kind, other::ToddCoxeter{W}) where {W} =
    init!(ToddCoxeter{W}(), kind, other)
ToddCoxeter(kind::congruence_kind, wg::WordGraph) = init!(ToddCoxeter(), kind, wg)
