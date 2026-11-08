# Copyright (c) 2026, James W. Swent
#
# Distributed under the terms of the GPL license version 3.

"""
cong-common.jl - shared CongruenceCommon helper wrappers
"""

"""
    CongruenceCommon

Abstract supertype shared by every congruence-style algorithm in
Semigroups.jl. The helpers documented on the
[Common congruence helpers](../cong-common-helpers.md) page are defined
on this supertype and dispatch to whichever concrete subtype is passed
in.

`CongruenceCommon` is itself a subtype of [`Runner`](@ref
Semigroups.Runner), so all runner methods (`run!`, `run_for!`,
`finished`, `timed_out`, `current_state`, etc.) work on every congruence
algorithm.

Word arguments and results use the representation of the input presentation.
String algorithms accept ASCII `AbstractString` inputs and return owning `String`
values; numeric algorithms accept integer vectors. No implicit conversion occurs
between these representations.
"""
abstract type CongruenceCommon{W} <: Runner end

_word_type(::CongruenceCommon{W}) where {W} = W

function _require_same_word_type(x, y)
    _word_type(x) === _word_type(y) || throw(
        ArgumentError(
            "word representations must agree; convert the presentation explicitly",
        ),
    )
    return nothing
end

mutable struct Congruence{W,B} <: CongruenceCommon{W}
    cxx_obj::B
    initial_graph::Union{Nothing,WordGraph}
end

_native_algorithm(::Type{Congruence}, ::Type{Vector{Int}}) = LibSemigroups.CongruenceWord
_native_algorithm(::Type{Congruence}, ::Type{String}) = LibSemigroups.CongruenceString
_wrap_congruence(x::LibSemigroups.CongruenceWord) =
    Congruence{Vector{Int},typeof(x)}(x, nothing)
_wrap_congruence(x::LibSemigroups.CongruenceString) =
    Congruence{String,typeof(x)}(x, nothing)

function _wrap_graph_congruence(native)
    result = _wrap_congruence(native)
    tc = LibSemigroups.cong_get_todd_coxeter(native)
    result.initial_graph = LibSemigroups.current_word_graph(tc)
    return result
end
Congruence{W}() where {W} = _wrap_congruence(_native_algorithm(Congruence, W)())
Congruence() = Congruence{Vector{Int}}()
Congruence(kind::congruence_kind, p::Presentation{W}) where {W} =
    init!(Congruence{W}(), kind, p)
"""
    Congruence(other::Congruence)
    copy(other::Congruence)
    deepcopy(other::Congruence)

Copy the mathematical input into independent native storage. Copies preserve
the presentation or initial word graph and all generating pairs, and reset
solver progress. The original and the copy can be changed independently.
"""
function Congruence(other::Congruence{W}) where {W}
    # Native 3.6.1 copies share race runners. A cold race has no shared state;
    # otherwise reconstruct from the original mathematical input, including
    # graph data which is not recorded in a graph-derived presentation's rules.
    if !started(other) && LibSemigroups.number_of_runners(_native(other)) == 0
        return _wrap_congruence(
            @wrap_libsemigroups_call _native_algorithm(Congruence, W)(_native(other))
        )
    end
    result = if other.initial_graph === nothing
        Congruence(kind(other), presentation(other))
    else
        to(Congruence{W}, kind(other), other.initial_graph)
    end
    for (lhs, rhs) in generating_pairs(other)
        add_generating_pair!(result, lhs, rhs)
    end
    return result
end

function init!(c::Congruence)
    @wrap_libsemigroups_call LibSemigroups.init!(_native(c))
    c.initial_graph = nothing
    return c
end

function init!(c::Congruence, kind::congruence_kind, p::Presentation)
    _require_same_word_type(c, p)
    @wrap_libsemigroups_call LibSemigroups.init!(_native(c), kind, _native(p))
    c.initial_graph = nothing
    return c
end

Base.copy(c::Congruence) = Congruence(c)
Base.deepcopy_internal(c::Congruence, ::IdDict) = Base.copy(c)
Base.show(io::IO, c::Congruence) =
    print(io, LibSemigroups.to_human_readable_repr(_native(c)))

"""
  number_of_classes(cong::CongruenceCommon) -> UInt64

Return the number of classes of `cong`, triggering a full enumeration if
needed.
"""
number_of_classes(cong::CongruenceCommon) =
    @wrap_libsemigroups_call LibSemigroups.number_of_classes(_native(cong))

"""
  presentation(cong::CongruenceCommon) -> Presentation

Return the presentation associated with `cong`.
"""
presentation(cong::CongruenceCommon) =
    _wrap_presentation(LibSemigroups.presentation(_native(cong)))

"""
  kind(cong::CongruenceCommon) -> congruence_kind

Return whether `cong` is a one-sided or two-sided congruence.
"""
kind(cong::CongruenceCommon) = LibSemigroups.kind(_native(cong))

number_of_generating_pairs(cong::CongruenceCommon) =
    Int(LibSemigroups.number_of_generating_pairs(_native(cong)))
generating_pairs(cong::CongruenceCommon) =
    _word_pairs_from_cpp(_word_type(cong), LibSemigroups.generating_pairs(_native(cong)))


"""
    add_generating_pair!(cong::CongruenceCommon, u::AbstractVector{<:Integer}, v::AbstractVector{<:Integer}) -> CongruenceCommon

Add a generating pair `(u, v)` to `cong`.

# Arguments

- `cong::CongruenceCommon`: the congruence to add a generating pair to.
- `u::AbstractVector{<:Integer}`: the left-hand side of the pair, as a
  1-based `Vector{Int}` of letter indices.
- `v::AbstractVector{<:Integer}`: the right-hand side of the pair, as a
  1-based `Vector{Int}` of letter indices.

Returns `cong` for chaining.

# Throws

- `LibsemigroupsError` if any letter in `u` or `v` is not in the
  alphabet of the underlying presentation.
"""
function add_generating_pair!(
    cong::CongruenceCommon,
    u::Union{AbstractVector{<:Integer},AbstractString},
    v::Union{AbstractVector{<:Integer},AbstractString},
)
    cpp_u = _word_to_cpp(_word_type(cong), u)
    cpp_v = _word_to_cpp(_word_type(cong), v)
    _check_generating_pair_capacity(cong)
    @wrap_libsemigroups_call LibSemigroups.cong_common_add_generating_pair!(
        _native(cong),
        cpp_u,
        cpp_v,
    )
    return cong
end

"""
    currently_contains(cong::CongruenceCommon, u::AbstractVector{<:Integer}, v::AbstractVector{<:Integer}) -> tril

Check whether the words `u` and `v` are already known to be equivalent
under `cong`, without triggering a run.

This function performs no enumeration of `cong`, so it is possible for
`u` and `v` to be equivalent in the congruence but for that not yet to
be known.

# Arguments

- `cong::CongruenceCommon`: the congruence to check containment in.
- `u::AbstractVector{<:Integer}`: the first word, as a 1-based
  `Vector{Int}` of letter indices.
- `v::AbstractVector{<:Integer}`: the second word, as a 1-based
  `Vector{Int}` of letter indices.

# Returns

A [`tril`](@ref Semigroups.tril) value:

- `tril_TRUE` if the words are known to belong to the congruence;
- `tril_FALSE` if the words are known not to belong to the congruence;
- `tril_unknown` otherwise.

# Throws

- `LibsemigroupsError` if any letter in `u` or `v` is not in the
  alphabet of the underlying presentation.

# See also

[`contains`](@ref Semigroups.contains(::CongruenceCommon, ::AbstractVector{<:Integer}, ::AbstractVector{<:Integer}))
"""
function currently_contains(
    cong::CongruenceCommon,
    u::Union{AbstractVector{<:Integer},AbstractString},
    v::Union{AbstractVector{<:Integer},AbstractString},
)
    cpp_u = _word_to_cpp(_word_type(cong), u)
    cpp_v = _word_to_cpp(_word_type(cong), v)
    return @wrap_libsemigroups_call LibSemigroups.cong_common_currently_contains(
        _native(cong),
        cpp_u,
        cpp_v,
    )
end

"""
    contains(cong::CongruenceCommon, u::AbstractVector{<:Integer}, v::AbstractVector{<:Integer}) -> Bool

Check whether the words `u` and `v` are equivalent under `cong`.

This function triggers a full enumeration of `cong`, which may never
terminate.

# Arguments

- `cong::CongruenceCommon`: the congruence to check containment in.
- `u::AbstractVector{<:Integer}`: the first word, as a 1-based
  `Vector{Int}` of letter indices.
- `v::AbstractVector{<:Integer}`: the second word, as a 1-based
  `Vector{Int}` of letter indices.

# Returns

`true` if `u` and `v` are equivalent under `cong`, `false` otherwise.

# Throws

- `LibsemigroupsError` if any letter in `u` or `v` is not in the
  alphabet of the underlying presentation.

!!! warning
    The Knuth-Bendix algorithm (and several other congruence algorithms)
    may never terminate for an undecidable input.

# See also

[`currently_contains`](@ref Semigroups.currently_contains(::CongruenceCommon, ::AbstractVector{<:Integer}, ::AbstractVector{<:Integer}))
"""
function contains(
    cong::CongruenceCommon,
    u::Union{AbstractVector{<:Integer},AbstractString},
    v::Union{AbstractVector{<:Integer},AbstractString},
)
    cpp_u = _word_to_cpp(_word_type(cong), u)
    cpp_v = _word_to_cpp(_word_type(cong), v)
    return @wrap_libsemigroups_call LibSemigroups.cong_common_contains(
        _native(cong),
        cpp_u,
        cpp_v,
    )
end

"""
    reduce_no_run(cong::CongruenceCommon, w::AbstractVector{<:Integer}) -> Vector{Int}

Reduce the word `w` using the current state of `cong`, without
triggering an enumeration.

The output word is equivalent to `w` in the congruence represented by
`cong`. If `cong` is [`finished`](@ref Semigroups.finished), the output
is a normal form for `w`. Otherwise, equivalent input words may produce
different output words.

# Arguments

- `cong::CongruenceCommon`: the congruence to reduce in.
- `w::AbstractVector{<:Integer}`: the word to reduce, as a 1-based
  `Vector{Int}` of letter indices.

# Returns

A word in the algorithm's representation, describing a word equivalent to `w` under the
current rules of `cong`.

# Throws

- `LibsemigroupsError` if any letter in `w` is not in the alphabet of
  the underlying presentation.

# See also

[`reduce`](@ref Semigroups.reduce(::CongruenceCommon, ::AbstractVector{<:Integer}))
"""
function reduce_no_run(
    cong::CongruenceCommon,
    w::Union{AbstractVector{<:Integer},AbstractString},
)
    cpp_w = _word_to_cpp(_word_type(cong), w)
    result = @wrap_libsemigroups_call LibSemigroups.cong_common_reduce_no_run(
        _native(cong),
        cpp_w,
    )
    return _word_from_cpp(_word_type(cong), result)
end

"""
    reduce(cong::CongruenceCommon, w::AbstractVector{<:Integer}) -> Vector{Int}

Reduce the word `w` to a normal form under `cong`.

This function triggers a full enumeration of `cong`. The output word is
a normal form for `w` in the congruence.

# Arguments

- `cong::CongruenceCommon`: the congruence to reduce in.
- `w::AbstractVector{<:Integer}`: the word to reduce, as a 1-based
  `Vector{Int}` of letter indices.

# Returns

A word in the algorithm's representation, describing a normal form of `w` in `cong`.

# Throws

- `LibsemigroupsError` if any letter in `w` is not in the alphabet of
  the underlying presentation.

!!! warning
    The Knuth-Bendix algorithm (and several other congruence algorithms)
    may never terminate for an undecidable input.

!!! note
    `Semigroups.reduce` is **not** exported, since exporting it would
    shadow `Base.reduce`. Use the module-qualified form
    `Semigroups.reduce(cong, w)`.

# See also

[`reduce_no_run`](@ref Semigroups.reduce_no_run(::CongruenceCommon, ::AbstractVector{<:Integer}))
"""
function reduce(cong::CongruenceCommon, w::Union{AbstractVector{<:Integer},AbstractString})
    cpp_w = _word_to_cpp(_word_type(cong), w)
    result = @wrap_libsemigroups_call LibSemigroups.cong_common_reduce(_native(cong), cpp_w)
    return _word_from_cpp(_word_type(cong), result)
end

"""
    normal_forms(cong::CongruenceCommon) -> Vector{Vector{Int}}

Return the normal forms of every congruence class of `cong`.

The order of the classes, and the normal form chosen for each class,
are determined by the reduction order of `cong`. This function triggers
a full enumeration of `cong`.

# Returns

A `Vector{W}` of words, where `W` is the algorithm's word representation, one per congruence class.

!!! warning
    The Knuth-Bendix algorithm (and several other congruence algorithms)
    may never terminate for an undecidable input. If the congruence has
    infinitely many classes, this function does not return.

# See also

[`partition`](@ref Semigroups.partition(::CongruenceCommon, ::AbstractVector{<:AbstractVector{<:Integer}})),
[`non_trivial_classes`](@ref Semigroups.non_trivial_classes(::CongruenceCommon, ::CongruenceCommon))
"""
function normal_forms(cong::CongruenceCommon)
    nf = @wrap_libsemigroups_call LibSemigroups.cong_common_normal_forms(_native(cong))
    return _words_from_cpp(_word_type(cong), nf)
end

"""
    partition(cong::CongruenceCommon, words::AbstractVector{<:AbstractVector{<:Integer}}) -> Vector{Vector{Vector{Int}}}

Partition `words` into congruence classes induced by `cong`.

Each returned class is a list of the input words that belong to the
same congruence class. This function triggers a full enumeration of
`cong`.

# Arguments

- `cong::CongruenceCommon`: the congruence used to partition the words.
- `words::AbstractVector{<:AbstractVector{<:Integer}}`: the input words,
  each a 1-based `Vector{Int}` of letter indices.

# Returns

A `Vector` of classes; each class is a vector of words in the algorithm's representation.

# Throws

- `LibsemigroupsError` if `cong` has infinitely many classes (the
  partition would not be finite).

# See also

[`non_trivial_classes`](@ref Semigroups.non_trivial_classes(::CongruenceCommon, ::CongruenceCommon)),
[`normal_forms`](@ref Semigroups.normal_forms(::CongruenceCommon))
"""
function partition(cong::CongruenceCommon, words::AbstractVector)
    native_words = _words_to_cpp(_word_type(cong), words)
    classes = @wrap_libsemigroups_call LibSemigroups.cong_common_partition(
        _native(cong),
        native_words,
    )
    return _classes_from_cpp(_word_type(cong), classes)
end

"""
    non_trivial_classes(cong1::CongruenceCommon, cong2::CongruenceCommon) -> Vector{Vector{Vector{Int}}}

Return the classes of size at least 2 in the partition of the normal
forms of `cong2` induced by `cong1`.

Here `cong1` must represent a coarser congruence than `cong2` (i.e. one
with fewer classes). This function triggers a full enumeration of both
arguments.

This function does **not** compute the normal forms of `cong2`,
partition them by `cong1`, and filter; it can therefore return the
non-trivial classes even when one of `cong1` or `cong2` has infinitely
many classes, provided there are only finitely many finite non-trivial
classes.

# Arguments

- `cong1::CongruenceCommon`: the coarser congruence.
- `cong2::CongruenceCommon`: the finer congruence.

# Returns

A `Vector` of non-trivial classes; each class is a vector of words in the algorithm's representation.

# Throws

- `LibsemigroupsError` if `cong1` has infinitely many classes and
  `cong2` has finitely many classes (so that there is at least one
  infinite non-trivial class).
- `LibsemigroupsError` if the alphabets of the underlying presentations
  of `cong1` and `cong2` are not equal.
- `LibsemigroupsError` if [`gilman_graph`](@ref Semigroups.gilman_graph)
  of `cong1` has fewer nodes than that of `cong2` (Knuth-Bendix only).

!!! warning
    The Knuth-Bendix algorithm (and several other congruence algorithms)
    may never terminate for an undecidable input.

# See also

[`partition`](@ref Semigroups.partition(::CongruenceCommon, ::AbstractVector{<:AbstractVector{<:Integer}})),
[`normal_forms`](@ref Semigroups.normal_forms(::CongruenceCommon))
"""
function non_trivial_classes(cong1::CongruenceCommon, cong2::CongruenceCommon)
    _require_same_word_type(cong1, cong2)
    classes = @wrap_libsemigroups_call LibSemigroups.cong_common_non_trivial_classes(
        _native(cong1),
        _native(cong2),
    )
    return _classes_from_cpp(_word_type(cong1), classes)
end

# A one-sided completion introduces an auxiliary generator when a pair is added.
# Validate before changing the native object's generating pairs.
_check_generating_pair_capacity(::CongruenceCommon) = nothing

function _check_generating_pair_capacity(c::Congruence{String})
    if kind(c) == onesided && length(alphabet(presentation(c))) >= 128
        throw(
            ArgumentError("a one-sided string congruence needs an unused ASCII generator"),
        )
    end
    return nothing
end

function _classes_from_cpp(::Type{W}, classes) where {W}
    result = Vector{Vector{W}}()
    GC.@preserve classes begin
        for cls in classes
            push!(result, W[_word_from_cpp(W, word) for word in cls])
        end
    end
    return result
end
