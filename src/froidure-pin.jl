# Copyright (c) 2026, James W. Swent, J. D. Mitchell
#
# Distributed under the terms of the GPL license version 3.
#
# The full license is in the file LICENSE, distributed with this software.

"""
froidure-pin.jl - FroidurePin{E} high-level Julia wrapper

Provides a parametric `FroidurePin{E}` type wrapping the CxxWrap-bound
C++ `FroidurePin<E>` template instantiations. Follows the same three-layer
pattern as `transf.jl`: CxxWrap type aliases, union type, private helpers,
mutable struct, constructors, and method wrappers.
"""

# ============================================================================
# CxxWrap type aliases — concrete FroidurePin<E> instantiations
# ============================================================================

const FroidurePinBase = LibSemigroups.FroidurePinBase

const FroidurePinTransf1 = LibSemigroups.FroidurePinTransf1
const FroidurePinTransf2 = LibSemigroups.FroidurePinTransf2
const FroidurePinTransf4 = LibSemigroups.FroidurePinTransf4

const FroidurePinPPerm1 = LibSemigroups.FroidurePinPPerm1
const FroidurePinPPerm2 = LibSemigroups.FroidurePinPPerm2
const FroidurePinPPerm4 = LibSemigroups.FroidurePinPPerm4

const FroidurePinPerm1 = LibSemigroups.FroidurePinPerm1
const FroidurePinPerm2 = LibSemigroups.FroidurePinPerm2
const FroidurePinPerm4 = LibSemigroups.FroidurePinPerm4

const FroidurePinBMat8 = LibSemigroups.FroidurePinBMat8

# ============================================================================
# Union type for cxx_obj field
# ============================================================================

const _FroidurePinCxx = Union{
    FroidurePinTransf1,
    FroidurePinTransf2,
    FroidurePinTransf4,
    FroidurePinPPerm1,
    FroidurePinPPerm2,
    FroidurePinPPerm4,
    FroidurePinPerm1,
    FroidurePinPerm2,
    FroidurePinPerm4,
    FroidurePinBMat8,
}

# ============================================================================
# Private helpers
# ============================================================================
# Index/word conversion helpers (_to_cpp, _from_cpp, _word_to_cpp,
# _word_from_cpp) are defined in word-graph.jl, transf.jl, and order.jl
# respectively. We reuse them here without redefinition.

# ============================================================================
# Type dispatch helpers
# ============================================================================

"""
    _cxx_fp_type(::Type{E}) -> Type

Map a high-level Julia element type to its CxxWrap FroidurePin constructor type.
"""
_cxx_fp_type(::Type{Transf{UInt8}}) = FroidurePinTransf1
_cxx_fp_type(::Type{Transf{UInt16}}) = FroidurePinTransf2
_cxx_fp_type(::Type{Transf{UInt32}}) = FroidurePinTransf4

_cxx_fp_type(::Type{PPerm{UInt8}}) = FroidurePinPPerm1
_cxx_fp_type(::Type{PPerm{UInt16}}) = FroidurePinPPerm2
_cxx_fp_type(::Type{PPerm{UInt32}}) = FroidurePinPPerm4

_cxx_fp_type(::Type{Perm{UInt8}}) = FroidurePinPerm1
_cxx_fp_type(::Type{Perm{UInt16}}) = FroidurePinPerm2
_cxx_fp_type(::Type{Perm{UInt32}}) = FroidurePinPerm4

_cxx_fp_type(::Type{T}) where {T<:BMat8} = FroidurePinBMat8

"""
    _wrap_element(::Type{E}, raw) -> E

Wrap a raw CxxWrap element back into the high-level Julia type.
"""
_wrap_element(::Type{Transf{T}}, raw) where {T} = Transf{T}(raw)
_wrap_element(::Type{PPerm{T}}, raw) where {T} = PPerm{T}(raw)
_wrap_element(::Type{Perm{T}}, raw) where {T} = Perm{T}(raw)
_wrap_element(::Type{T}, raw) where {T<:BMat8} = raw  # BMat8 is a direct alias

"""
    _cxx_element(x) -> CxxWrap object

Extract the CxxWrap object from a high-level Julia element.
"""
_cxx_element(x::Transf) = x.cxx_obj
_cxx_element(x::PPerm) = x.cxx_obj
_cxx_element(x::Perm) = x.cxx_obj
_cxx_element(x::BMat8) = x  # BMat8 is a direct alias

"""
    _copy_cxx_element(raw) -> CxxWrap object (Allocated)

Copy a raw CxxWrap element to produce an Allocated (owning) copy.
Needed when iterating CxxWrap StdVectors, which yield Dereferenced
references that don't own their memory.
"""
_copy_cxx_element(raw::Union{_TransfTypes,_PPermTypes,_PermTypes,BMat8}) =
    LibSemigroups.copy(raw)

"""
    _fp_element_type(::Type{E}) -> Type

Normalize element type for the FroidurePin{E} type parameter.
CxxWrap creates BMat8Allocated as a subtype of BMat8; we normalize
to BMat8 so that FroidurePin{BMat8} is the canonical type.
"""
_fp_element_type(::Type{E}) where {E} = E
_fp_element_type(::Type{T}) where {T<:BMat8} = BMat8

# ============================================================================
# FroidurePin{E} mutable struct
# ============================================================================

"""
    FroidurePin{E}

Type implementing the Froidure-Pin algorithm.

A `FroidurePin{E}` instance is defined by a generating set of elements of
type `E`, and the main function is [`run!`](@ref), which implements the
Froidure-Pin algorithm as described by Froidure and Pin. If [`run!`](@ref)
is invoked and [`finished`](@ref) returns `true`, then the size
[`length`](@ref), the left and right Cayley graphs
[`left_cayley_graph`](@ref) and [`right_cayley_graph`](@ref) are
determined, and a confluent terminating presentation for the semigroup is
known.

Supported element types:
- [`Transf{UInt8}`](@ref Semigroups.Transf), [`Transf{UInt16}`](@ref Semigroups.Transf), [`Transf{UInt32}`](@ref Semigroups.Transf) (transformations)
- [`PPerm{UInt8}`](@ref Semigroups.PPerm), [`PPerm{UInt16}`](@ref Semigroups.PPerm), [`PPerm{UInt32}`](@ref Semigroups.PPerm) (partial permutations)
- [`Perm{UInt8}`](@ref Semigroups.Perm), [`Perm{UInt16}`](@ref Semigroups.Perm), [`Perm{UInt32}`](@ref Semigroups.Perm) (permutations)
- [`BMat8`](@ref Semigroups.BMat8) (boolean matrices up to 8x8)

# Example
```julia
using Semigroups

S = FroidurePin(Transf([2, 1, 3]), Transf([2, 3, 1]))
length(S)  # 6 (symmetric group S_3)
```

# See also
- [`FroidurePinBase`](@ref Semigroups.FroidurePinBase)
- [`Runner`](@ref Semigroups.Runner)
"""
mutable struct FroidurePin{E}
    cxx_obj::_FroidurePinCxx
end

# ============================================================================
# Constructors
# ============================================================================

"""
    FroidurePin(gens::Vector{E}) where {E}

Construct a [`FroidurePin{E}`](@ref Semigroups.FroidurePin) from a
container of generators.

This function constructs a `FroidurePin{E}` instance from the vector of
generators `gens`, after verifying that the proposed generators all have
equal degree.

# Arguments
- `gens::Vector{E}`: a non-empty vector of generators. All generators
  must have the same degree.

# Throws
- `ErrorException`: if `gens` is empty.
- `LibsemigroupsError`: if `degree(x) != degree(y)` for any `x` and `y`
  in `gens`.

# Example
```julia
using Semigroups

S = FroidurePin([Transf([2, 1, 3]), Transf([2, 3, 1])])
length(S)  # 6
```

# See also
- [`FroidurePin(x::E, xs::E...)`](@ref)
"""
function FroidurePin(gens::Vector{E}) where {E}
    isempty(gens) && error("At least one generator is required")

    # Normalize element type (BMat8Allocated -> BMat8)
    NE = _fp_element_type(E)

    FPType = _cxx_fp_type(NE)
    cxx_gens = [_cxx_element(g) for g in gens]

    n = length(cxx_gens)
    if n == 1
        cxx_obj = @wrap_libsemigroups_call FPType(cxx_gens[1])
    elseif n == 2
        cxx_obj = @wrap_libsemigroups_call FPType(cxx_gens[1], cxx_gens[2])
    elseif n == 3
        cxx_obj = @wrap_libsemigroups_call FPType(cxx_gens[1], cxx_gens[2], cxx_gens[3])
    elseif n == 4
        cxx_obj = @wrap_libsemigroups_call FPType(
            cxx_gens[1],
            cxx_gens[2],
            cxx_gens[3],
            cxx_gens[4],
        )
    else
        # >4 generators: construct with first, then add the rest
        cxx_obj = @wrap_libsemigroups_call FPType(cxx_gens[1])
        for i = 2:n
            @wrap_libsemigroups_call LibSemigroups.add_generator!(cxx_obj, cxx_gens[i])
        end
    end

    return FroidurePin{NE}(cxx_obj)
end

"""
    FroidurePin(x::E, xs::E...) where {E}

Construct a [`FroidurePin{E}`](@ref Semigroups.FroidurePin) from one or
more generators given as positional arguments.

This is a convenience constructor equivalent to
`FroidurePin(E[x, xs...])`.

# Arguments
- `x::E`: the first generator.
- `xs::E...`: zero or more additional generators of the same type.

# Throws
    - `LibsemigroupsError`: if `degree(x) != degree(y)` for any generators
    `x` and `y`.

# Example
```julia
using Semigroups

S = FroidurePin(Transf([2, 1, 3]), Transf([2, 3, 1]))
length(S)  # 6
```

# See also
- [`FroidurePin(gens::Vector{E})`](@ref)
"""
function FroidurePin(x::E, xs::E...) where {E}
    return FroidurePin(E[x, xs...])
end

# ============================================================================
# Size queries
# ============================================================================

"""
    Base.length(fp::FroidurePin) -> Int

Return the size of a [`FroidurePin`](@ref Semigroups.FroidurePin) instance.

This function fully enumerates `fp` and then returns the number of
elements.

# Complexity
At worst ``O(|S| n)`` where ``S`` is the semigroup represented by `fp`
and ``n`` is [`number_of_generators`](@ref)`(fp)`.

!!! note
    This function triggers a full enumeration.

# Example
```julia
using Semigroups

S = FroidurePin(Transf([2, 1, 3]), Transf([2, 3, 1]))
length(S)  # 6
```

# See also
- [`current_size`](@ref)
"""
Base.length(fp::FroidurePin) = Int(LibSemigroups.size(fp.cxx_obj))

"""
    current_size(fp::FroidurePin) -> Int

Return the number of elements so far enumerated.

This is only the actual size of the semigroup if `fp` is fully enumerated.

# Complexity
Constant.

!!! note
    This function does not trigger any enumeration.

# Example
```julia
using Semigroups

S = FroidurePin(Transf([2, 1, 3]), Transf([2, 3, 1]))
current_size(S)  # 2 (only generators known)
```

# See also
- [`length`](@ref Base.length)
"""
current_size(fp::FroidurePin) = Int(LibSemigroups.current_size(fp.cxx_obj))

"""
    degree(fp::FroidurePin) -> Int

Return the degree of any and all elements.

This function returns the degree of any (and hence all) elements of the
semigroup represented by `fp`.

# Complexity
Constant.

!!! note
    This function does not trigger any enumeration.

# Example
```julia
using Semigroups

S = FroidurePin(Transf([2, 1, 3]), Transf([2, 3, 1]))
degree(S)  # 3
```
"""
degree(fp::FroidurePin) = Int(LibSemigroups.degree(fp.cxx_obj))

"""
    number_of_generators(fp::FroidurePin) -> Int

Return the number of generators.

This function returns the number of generators of the semigroup
represented by `fp`.

!!! note
    This function does not trigger any enumeration.

# Example
```julia
using Semigroups

S = FroidurePin(Transf([2, 1, 3]), Transf([2, 3, 1]))
number_of_generators(S)  # 2
```

# See also
- [`generator`](@ref)
"""
number_of_generators(fp::FroidurePin) = Int(LibSemigroups.number_of_generators(fp.cxx_obj))

"""
    enumerate!(fp::FroidurePin, limit::Integer) -> FroidurePin

Enumerate until at least a specified number of elements are found.

If `fp` is already fully enumerated, or the number of elements
previously enumerated exceeds `limit`, then calling this function does
nothing. Otherwise, [`run!`](@ref) attempts to find at least the maximum
of `limit` and [`batch_size`](@ref) additional elements of the semigroup.

# Arguments
- `fp::FroidurePin`: the FroidurePin instance.
- `limit::Integer`: the approximate limit for
  [`current_size`](@ref)`(fp)`.

# Complexity
At worst ``O(m n)`` where ``m`` equals `limit` and ``n`` is
[`number_of_generators`](@ref)`(fp)`.

# Example
```julia
using Semigroups

S = FroidurePin(Transf([2, 1, 3]), Transf([2, 3, 1]))
enumerate!(S, 4)
current_size(S)  # >= 4
```

# See also
- [`run!`](@ref)
- [`current_size`](@ref)
"""
function enumerate!(fp::FroidurePin, limit::Integer)
    lim = UInt(limit)
    @wrap_libsemigroups_call LibSemigroups.enumerate!(fp.cxx_obj, lim)
    return fp
end

# ============================================================================
# Runner delegation
# ============================================================================
# Every public Runner method is delegated through fp.cxx_obj.
# Mutating methods return fp for chaining; query methods return the result.

"""
    run!(fp::FroidurePin) -> FroidurePin

Run the Froidure-Pin algorithm until [`finished`](@ref).

At the end of this call `fp` is either [`finished`](@ref) or
[`dead`](@ref). Returns `fp` for method chaining.

# See also
- [`run_for!`](@ref)
- [`run_until!`](@ref)
- [`finished`](@ref)
"""
function run!(fp::FroidurePin)
    LibSemigroups.run!(fp.cxx_obj)
    return fp
end

"""
    run_for!(fp::FroidurePin, t::TimePeriod) -> FroidurePin

Run the Froidure-Pin algorithm for a specified amount of time.

At the end of this call `fp` is either [`finished`](@ref),
[`dead`](@ref), or [`timed_out`](@ref). Returns `fp` for method
chaining.

# Arguments
- `fp::FroidurePin`: the FroidurePin instance.
- `t::TimePeriod`: the duration to run for (e.g. `Second(1)`,
  `Millisecond(500)`).

# Example
```julia
run_for!(S, Second(1))
run_for!(S, Millisecond(500))
```

# See also
- [`run!`](@ref)
- [`run_until!`](@ref)
- [`timed_out`](@ref)
"""
function run_for!(fp::FroidurePin, t::TimePeriod)
    ns = convert(Nanosecond, t)
    Dates.value(ns) >= 0 ||
        throw(ArgumentError("run_for! requires a non-negative duration, got $t"))
    LibSemigroups.run_for!(fp.cxx_obj, Int64(Dates.value(ns)))
    return fp
end

function run_until!(f::Function, fp::FroidurePin)
    sf = @safe_cfunction($f, Cuchar, ())
    GC.@preserve sf LibSemigroups.run_until!(fp.cxx_obj, sf)
    return fp
end

"""
    run_until!(fp::FroidurePin, f::Function) -> FroidurePin

Run the Froidure-Pin algorithm until a nullary predicate returns `true`
or [`finished`](@ref).

At the end of this call `fp` is either [`finished`](@ref),
[`dead`](@ref), or [`stopped_by_predicate`](@ref). Returns `fp` for
method chaining.

# Arguments
- `fp::FroidurePin`: the FroidurePin instance.
- `f::Function`: a nullary predicate (a callable taking no arguments and
  returning `Bool`).

Supports do-block syntax:

```julia
run_until!(S) do
    current_size(S) >= 10
end
```

# See also
- [`run!`](@ref)
- [`run_for!`](@ref)
- [`stopped_by_predicate`](@ref)
"""
run_until!(fp::FroidurePin, f::Function) = run_until!(f, fp)

"""
    init!(fp::FroidurePin) -> FroidurePin

Initialize an existing [`FroidurePin`](@ref Semigroups.FroidurePin)
object.

This function puts `fp` back into the same state as if it had been newly
default constructed. Returns `fp` for method chaining.

!!! warning
    This function is not thread-safe.

# See also
- [`FroidurePin`](@ref Semigroups.FroidurePin)
"""
function init!(fp::FroidurePin)
    LibSemigroups.init!(fp.cxx_obj)
    return fp
end

"""
    kill!(fp::FroidurePin)

Stop [`run!`](@ref) from running (thread-safe).

This function can be used to terminate [`run!`](@ref) from another
thread. After [`kill!`](@ref) has been called, `fp` may no longer be in a
valid state, but will return `true` from [`dead`](@ref).

# See also
- [`dead`](@ref)
- [`finished`](@ref)
"""
kill!(fp::FroidurePin) = LibSemigroups.kill!(fp.cxx_obj)

"""
    finished(fp::FroidurePin) -> Bool

Check if [`run!`](@ref) has been run to completion.

Returns `true` if [`run!`](@ref) has been run to completion and `false`
otherwise.

# See also
- [`started`](@ref)
- [`stopped`](@ref)
"""
finished(fp::FroidurePin) = LibSemigroups.finished(fp.cxx_obj)

"""
    Base.success(fp::FroidurePin) -> Bool

Check if [`run!`](@ref) has been run to completion successfully.

Returns `true` if [`run!`](@ref) has been run to completion and it was
successful. The default implementation is equivalent to calling
[`finished`](@ref).

# See also
- [`finished`](@ref)
"""
Base.success(fp::FroidurePin) = LibSemigroups.success(fp.cxx_obj)

"""
    started(fp::FroidurePin) -> Bool

Check if [`run!`](@ref) has been called at least once.

Returns `true` if [`run!`](@ref) has started to run (it can be
currently running or not).

# See also
- [`finished`](@ref)
- [`running`](@ref)
"""
started(fp::FroidurePin) = LibSemigroups.started(fp.cxx_obj)

"""
    running(fp::FroidurePin) -> Bool

Check if currently running.

Returns `true` if [`run!`](@ref) is in the process of running and
`false` otherwise.

# See also
- [`finished`](@ref)
- [`started`](@ref)
"""
running(fp::FroidurePin) = LibSemigroups.running(fp.cxx_obj)

"""
    timed_out(fp::FroidurePin) -> Bool

Check if the amount of time passed to [`run_for!`](@ref) has elapsed.

Returns `true` if the last [`run_for!`](@ref) call timed out and `false`
otherwise.

# See also
- [`run_for!`](@ref)
- [`stopped`](@ref)
"""
timed_out(fp::FroidurePin) = LibSemigroups.timed_out(fp.cxx_obj)

"""
    stopped(fp::FroidurePin) -> Bool

Check if the runner is stopped.

This function can be used to check whether or not [`run!`](@ref) has
been stopped for whatever reason. In other words, it checks if
[`timed_out`](@ref), [`finished`](@ref), or [`dead`](@ref).

# See also
- [`timed_out`](@ref)
- [`finished`](@ref)
- [`dead`](@ref)
"""
stopped(fp::FroidurePin) = LibSemigroups.stopped(fp.cxx_obj)

"""
    dead(fp::FroidurePin) -> Bool

Check if the runner is dead.

This function can be used to check if [`run!`](@ref) should terminate
because it has been killed by another thread via [`kill!`](@ref).

# See also
- [`kill!`](@ref)
- [`stopped`](@ref)
"""
dead(fp::FroidurePin) = LibSemigroups.dead(fp.cxx_obj)

"""
    stopped_by_predicate(fp::FroidurePin) -> Bool

Check if the runner was stopped by the predicate passed to
[`run_until!`](@ref).

If `fp` is running, then the nullary predicate is called and its return
value is returned. If `fp` is not running, then `true` is returned if
and only if the last time `fp` was running it was stopped by the
predicate passed to [`run_until!`](@ref).

# Complexity
Constant.

# See also
- [`run_until!`](@ref)
- [`stopped`](@ref)
"""
stopped_by_predicate(fp::FroidurePin) = LibSemigroups.stopped_by_predicate(fp.cxx_obj)

"""
    running_for(fp::FroidurePin) -> Bool

Check if currently running for a particular length of time.

If `fp` is currently running because [`run_for!`](@ref) has been
invoked, then this function returns `true`. Otherwise, `false` is
returned.

# Complexity
Constant.

# See also
- [`run_for!`](@ref)
- [`running_for_how_long`](@ref)
"""
running_for(fp::FroidurePin) = LibSemigroups.running_for(fp.cxx_obj)

"""
    running_for_how_long(fp::FroidurePin) -> Nanosecond

Return the last value passed to [`run_for!`](@ref).

This function returns the last value passed as an argument to
[`run_for!`](@ref) (if any) as a `Dates.Nanosecond`.

# Complexity
Constant.

# See also
- [`run_for!`](@ref)
- [`running_for`](@ref)
"""
running_for_how_long(fp::FroidurePin) =
    Nanosecond(LibSemigroups.running_for_how_long(fp.cxx_obj))

"""
    running_until(fp::FroidurePin) -> Bool

Check if currently running until a nullary predicate returns `true`.

If `fp` is currently running because [`run_until!`](@ref) has been
invoked, then this function returns `true`. Otherwise, `false` is
returned.

# Complexity
Constant.

# See also
- [`run_until!`](@ref)
- [`stopped_by_predicate`](@ref)
"""
running_until(fp::FroidurePin) = LibSemigroups.running_until(fp.cxx_obj)

"""
    current_state(fp::FroidurePin) -> RunnerState

Return the current state of the runner.

Returns the current state of `fp` as a [`RunnerState`](@ref Semigroups.RunnerState)
value.

# Complexity
Constant.

# See also
- [`RunnerState`](@ref Semigroups.RunnerState)
"""
current_state(fp::FroidurePin) = LibSemigroups.current_state(fp.cxx_obj)

"""
    report_why_we_stopped(fp::FroidurePin)

Report why [`run!`](@ref) stopped.

Reports whether [`run!`](@ref) was stopped because it is
[`finished`](@ref), [`timed_out`](@ref), or [`dead`](@ref).

# See also
- [`string_why_we_stopped`](@ref)
"""
report_why_we_stopped(fp::FroidurePin) = LibSemigroups.report_why_we_stopped(fp.cxx_obj)

"""
    string_why_we_stopped(fp::FroidurePin) -> String

Return a human-readable string describing why [`run!`](@ref) stopped.

Returns a string indicating whether [`run!`](@ref) was stopped because
it is [`finished`](@ref), [`timed_out`](@ref), or [`dead`](@ref).

# See also
- [`report_why_we_stopped`](@ref)
"""
string_why_we_stopped(fp::FroidurePin) = LibSemigroups.string_why_we_stopped(fp.cxx_obj)

# ============================================================================
# Element access
# ============================================================================

"""
    Base.getindex(fp::FroidurePin{E}, i::Integer) -> E

Access the element with index `i`.

This function attempts to enumerate until at least `i` elements have
been found, then returns the element at position `i`.

# Arguments
- `fp::FroidurePin{E}`: the FroidurePin instance.
- `i::Integer`: the 1-based index of the element to access.

# Throws
- `BoundsError`: if `i` is less than `1` or greater than
  [`length`](@ref Base.length)`(fp)`.

!!! note
    This function triggers a full enumeration.

# Example
```julia
S = FroidurePin(Transf([2, 1, 3]), Transf([2, 3, 1]))
S[1]  # first element
```

# See also
- [`sorted_at`](@ref)
- [`generator`](@ref)
"""
function Base.getindex(fp::FroidurePin{E}, i::Integer) where {E}
    if i < 1 || i > length(fp)
        throw(BoundsError(fp, i))
    end
    idx = _to_cpp(i, UInt)
    raw = @wrap_libsemigroups_call LibSemigroups.at(fp.cxx_obj, idx)
    return _wrap_element(E, raw)
end

"""
    generator(fp::FroidurePin{E}, i::Integer) -> E

Return the generator with the specified index.

This function returns the generator with index `i`, where the order is
that in which the generators were added at construction, or via
[`push!`](@ref Base.push!), [`closure!`](@ref),
[`copy_closure`](@ref), or [`copy_add_generators`](@ref).

# Arguments
- `fp::FroidurePin{E}`: the FroidurePin instance.
- `i::Integer`: the 1-based index of a generator.

# Throws
- `LibsemigroupsError`: if `i` is greater than
  [`number_of_generators`](@ref)`(fp)`.

!!! note
    `generator(fp, j)` is in general not in position `j`.

!!! note
    This function does not trigger any enumeration.

# Example
```julia
S = FroidurePin(Transf([2, 1, 3]), Transf([2, 3, 1]))
generator(S, 1)  # first generator
```

# See also
- [`getindex`](@ref Base.getindex)
- [`sorted_at`](@ref)
"""
function generator(fp::FroidurePin{E}, i::Integer) where {E}
    idx = _to_cpp(i, UInt)
    raw = @wrap_libsemigroups_call LibSemigroups.generator(fp.cxx_obj, idx)
    return _wrap_element(E, raw)
end

"""
    sorted_at(fp::FroidurePin{E}, i::Integer) -> E

Access the element with the specified sorted index.

This function triggers a full enumeration, and returns the element
at position `i` when the elements are sorted.

# Arguments
- `fp::FroidurePin{E}`: the FroidurePin instance.
- `i::Integer`: the 1-based sorted index of the element to access.

# Throws
- `LibsemigroupsError`: if `i` is greater than
  [`length`](@ref Base.length)`(fp)`.

!!! note
    This function triggers a full enumeration.

# Example
```julia
S = FroidurePin(Transf([2, 1, 3]), Transf([2, 3, 1]))
sorted_at(S, 1)  # first element in sorted order
```

# See also
- [`getindex`](@ref Base.getindex)
- [`sorted_position`](@ref)
"""
function sorted_at(fp::FroidurePin{E}, i::Integer) where {E}
    idx = _to_cpp(i, UInt)
    raw = @wrap_libsemigroups_call LibSemigroups.sorted_at(fp.cxx_obj, idx)
    return _wrap_element(E, raw)
end

# ============================================================================
# Iteration
# ============================================================================

"""
    Base.iterate(fp::FroidurePin{E}[, state]) -> Union{Tuple{E, Int}, Nothing}

Iterate over all elements of the semigroup.

This function allows a [`FroidurePin{E}`](@ref Semigroups.FroidurePin)
instance to be used in `for` loops and with `collect`. Elements are
yielded in the order they were enumerated by the Froidure-Pin algorithm.

!!! note
    This function triggers a full enumeration on the first call
    (via [`length`](@ref Base.length)).

# Example
```julia
S = FroidurePin(Transf([2, 1, 3]), Transf([2, 3, 1]))
for x in S
    println(x)
end
elts = collect(S)  # Vector{Transf{UInt8}} of length 6
```

# See also
- [`getindex`](@ref Base.getindex)
- [`length`](@ref Base.length)
"""
function Base.iterate(fp::FroidurePin, state::Int = 1)
    if state > length(fp)
        return nothing
    end
    return (fp[state], state + 1)
end

"""
    Base.eltype(::Type{FroidurePin{E}}) where E -> Type

Return the element type `E` of a [`FroidurePin{E}`](@ref Semigroups.FroidurePin).

# Complexity
Constant.
"""
Base.eltype(::Type{FroidurePin{E}}) where {E} = E

Base.IteratorSize(::Type{<:FroidurePin}) = Base.HasLength()

# ============================================================================
# Copy
# ============================================================================

"""
    Base.copy(fp::FroidurePin{E}) -> FroidurePin{E}

Create an independent copy of the [`FroidurePin{E}`](@ref Semigroups.FroidurePin) instance.

This function constructs a new [`FroidurePin{E}`](@ref Semigroups.FroidurePin) from the
generators of `fp`. The returned instance is fully independent of `fp`
and can be enumerated or modified without affecting the original.

!!! note
    This function does not trigger any enumeration of `fp`.

# Example
```julia
S = FroidurePin(Transf([2, 1, 3]), Transf([2, 3, 1]))
T = copy(S)
length(T)  # 6, independently computed
```

# See also
- [`copy_closure`](@ref)
- [`copy_add_generators`](@ref)
"""
function Base.copy(fp::FroidurePin{E}) where {E}
    gens = [generator(fp, i) for i = 1:number_of_generators(fp)]
    return FroidurePin(gens)
end

# ============================================================================
# Display
# ============================================================================

"""
    Base.show(io::IO, fp::FroidurePin)

Display a human-readable summary of the [`FroidurePin`](@ref Semigroups.FroidurePin)
instance `fp` to the I/O stream `io`.

!!! note
    This function does not trigger any enumeration.
"""
function Base.show(io::IO, fp::FroidurePin)
    print(io, @wrap_libsemigroups_call LibSemigroups.to_human_readable_repr(fp.cxx_obj))
end

# ============================================================================
# Containment
# ============================================================================

"""
    Base.in(x::E, fp::FroidurePin{E}) where E -> Bool

Test membership of an element.

This function returns `true` if `x` belongs to `fp` and `false` if it
does not.

# Arguments
- `x::E`: an element to test for membership.
- `fp::FroidurePin{E}`: the FroidurePin instance.

!!! note
    This function may trigger a (partial) enumeration.

# Example
```julia
S = FroidurePin(Transf([2, 1, 3]), Transf([2, 3, 1]))
Transf([2, 1, 3]) in S   # true
Transf([1, 1, 1]) in S   # false
```

# See also
- [`position`](@ref)
- [`current_position`](@ref)
"""
function Base.in(x::E, fp::FroidurePin{E}) where {E}
    cxx_x = _cxx_element(x)
    return @wrap_libsemigroups_call LibSemigroups.contains(fp.cxx_obj, cxx_x)
end

# BMat8 dispatch: BMat8Allocated <: BMat8, so we need a fallback
function Base.in(x::BMat8, fp::FroidurePin{BMat8})
    cxx_x = _cxx_element(x)
    return @wrap_libsemigroups_call LibSemigroups.contains(fp.cxx_obj, cxx_x)
end

"""
    position(fp::FroidurePin{E}, x::E) where E -> Union{Int, UNDEFINED}

Find the position of an element with enumeration if necessary.

This function returns the 1-based position of `x` in `fp`, or
[`UNDEFINED`](@ref Semigroups.UNDEFINED) if `x` is not an element of `fp`.

# Arguments
- `fp::FroidurePin{E}`: the FroidurePin instance.
- `x::E`: an element whose position is sought.

!!! note
    This function triggers a full enumeration.

# Example
```julia
S = FroidurePin(Transf([2, 1, 3]), Transf([2, 3, 1]))
position(S, Transf([2, 1, 3]))  # 1-based index
```

# See also
- [`current_position`](@ref)
- [`sorted_position`](@ref)
- [`in`](@ref Base.in)
"""
function position(fp::FroidurePin{E}, x::E) where {E}
    cxx_x = _cxx_element(x)
    raw = @wrap_libsemigroups_call LibSemigroups.position(fp.cxx_obj, cxx_x)
    return _from_cpp(raw)
end

function position(fp::FroidurePin{BMat8}, x::BMat8)
    cxx_x = _cxx_element(x)
    raw = @wrap_libsemigroups_call LibSemigroups.position(fp.cxx_obj, cxx_x)
    return _from_cpp(raw)
end

"""
    sorted_position(fp::FroidurePin{E}, x::E) where E -> Union{Int, UNDEFINED}

Return the sorted index of an element.

This function returns the 1-based position of `x` in the elements of
`fp` when they are sorted, or [`UNDEFINED`](@ref Semigroups.UNDEFINED)
if `x` is not an element of `fp`.

# Arguments
- `fp::FroidurePin{E}`: the FroidurePin instance.
- `x::E`: an element whose sorted position is sought.

!!! note
    This function triggers a full enumeration.

# See also
- [`current_position`](@ref)
- [`position`](@ref)
- [`to_sorted_position`](@ref)
- [`sorted_at`](@ref)
"""
function sorted_position(fp::FroidurePin{E}, x::E) where {E}
    cxx_x = _cxx_element(x)
    raw = @wrap_libsemigroups_call LibSemigroups.sorted_position(fp.cxx_obj, cxx_x)
    return _from_cpp(raw)
end

function sorted_position(fp::FroidurePin{BMat8}, x::BMat8)
    cxx_x = _cxx_element(x)
    raw = @wrap_libsemigroups_call LibSemigroups.sorted_position(fp.cxx_obj, cxx_x)
    return _from_cpp(raw)
end

"""
    to_sorted_position(fp::FroidurePin, i::Integer) -> Union{Int, UNDEFINED}

Return the sorted index of an element via its index.

This function returns the 1-based position of the element with index `i`
when the elements are sorted, or [`UNDEFINED`](@ref Semigroups.UNDEFINED)
if `i` is greater than [`length`](@ref Base.length)`(fp)`.

# Arguments
- `fp::FroidurePin`: the FroidurePin instance.
- `i::Integer`: the 1-based index of the element.

!!! note
    This function triggers a full enumeration.

# See also
- [`sorted_position`](@ref)
- [`sorted_at`](@ref)
"""
function to_sorted_position(fp::FroidurePin, i::Integer)
    idx = _to_cpp(i, UInt)
    raw = @wrap_libsemigroups_call LibSemigroups.to_sorted_position(fp.cxx_obj, idx)
    return _from_cpp(raw)
end

"""
    current_position(fp::FroidurePin{E}, x::E) where E -> Union{Int, UNDEFINED}

Find the position of an element with no enumeration.

This function returns the 1-based position of the element `x` in `fp`
if it is already known to belong to `fp`, or
[`UNDEFINED`](@ref Semigroups.UNDEFINED) if not. If `fp` is not yet
fully enumerated, then this function may return
[`UNDEFINED`](@ref Semigroups.UNDEFINED) even when `x` does belong to `fp`.

# Arguments
- `fp::FroidurePin{E}`: the FroidurePin instance.
- `x::E`: an element whose position is sought.

!!! note
    This function does not trigger any enumeration.

# See also
- [`position`](@ref)
- [`sorted_position`](@ref)
"""
function current_position(fp::FroidurePin{E}, x::E) where {E}
    cxx_x = _cxx_element(x)
    raw = @wrap_libsemigroups_call LibSemigroups.current_position(fp.cxx_obj, cxx_x)
    return _from_cpp(raw)
end

function current_position(fp::FroidurePin{BMat8}, x::BMat8)
    cxx_x = _cxx_element(x)
    raw = @wrap_libsemigroups_call LibSemigroups.current_position(fp.cxx_obj, cxx_x)
    return _from_cpp(raw)
end

"""
    current_position(fp::FroidurePin, w::AbstractVector{<:Integer}) -> Union{Int, UNDEFINED}

Return the position corresponding to a word.

This function returns the 1-based position of the element corresponding
to the word `w` (a vector of 1-based generator indices). No enumeration
is performed, and [`UNDEFINED`](@ref Semigroups.UNDEFINED) is returned
if the word does not currently correspond to an element.

# Arguments
- `fp::FroidurePin`: the FroidurePin instance.
- `w::AbstractVector{<:Integer}`: a word in the generators (1-based
  generator indices).

# Throws
- `LibsemigroupsError`: if any letter in `w` is out of range (exceeds
  [`number_of_generators`](@ref)`(fp)`).

# Complexity
``O(n)`` where ``n`` is the length of the word `w`.

!!! note
    This function does not trigger any enumeration.

# See also
- [`position`](@ref)
- [`current_position`](@ref current_position(::FroidurePin{E}, ::E) where E)
"""
function current_position(fp::FroidurePin, w::AbstractVector{<:Integer})
    cw = _word_to_cpp(w)
    raw = @wrap_libsemigroups_call LibSemigroups.current_position(fp.cxx_obj, cw)
    return _from_cpp(raw)
end

# ============================================================================
# Modification
# ============================================================================

"""
    Base.push!(fp::FroidurePin{E}, x::E) where E -> FroidurePin{E}

Add a new generator `x` to the semigroup `fp`.

Returns `fp` for method chaining.

# Example
```julia
S = FroidurePin(Transf([2, 1, 3]))
push!(S, Transf([2, 3, 1]))
length(S)  # 6
```
"""
function Base.push!(fp::FroidurePin{E}, x::E) where {E}
    cxx_x = _cxx_element(x)
    @wrap_libsemigroups_call LibSemigroups.add_generator!(fp.cxx_obj, cxx_x)
    return fp
end

function Base.push!(fp::FroidurePin{BMat8}, x::BMat8)
    cxx_x = _cxx_element(x)
    @wrap_libsemigroups_call LibSemigroups.add_generator!(fp.cxx_obj, cxx_x)
    return fp
end

"""
    closure!(fp::FroidurePin{E}, x::E) where E -> FroidurePin{E}

Add element `x` to the semigroup `fp` if it is not already contained,
and re-enumerate.

Returns `fp` for method chaining.
"""
function closure!(fp::FroidurePin{E}, x::E) where {E}
    cxx_x = _cxx_element(x)
    @wrap_libsemigroups_call LibSemigroups.closure!(fp.cxx_obj, cxx_x)
    return fp
end

function closure!(fp::FroidurePin{BMat8}, x::BMat8)
    cxx_x = _cxx_element(x)
    @wrap_libsemigroups_call LibSemigroups.closure!(fp.cxx_obj, cxx_x)
    return fp
end

"""
    copy_closure(fp::FroidurePin{E}, x::E) where E -> FroidurePin{E}

Return a new `FroidurePin{E}` that is a copy of `fp` with element `x`
added as a generator (if not already contained), and re-enumerated.
"""
function copy_closure(fp::FroidurePin{E}, x::E) where {E}
    cxx_x = _cxx_element(x)
    new_cxx = @wrap_libsemigroups_call LibSemigroups.copy_closure(fp.cxx_obj, cxx_x)
    return FroidurePin{E}(new_cxx)
end

function copy_closure(fp::FroidurePin{BMat8}, x::BMat8)
    cxx_x = _cxx_element(x)
    new_cxx = @wrap_libsemigroups_call LibSemigroups.copy_closure(fp.cxx_obj, cxx_x)
    return FroidurePin{BMat8}(new_cxx)
end

"""
    copy_add_generators(fp::FroidurePin{E}, x::E) where E -> FroidurePin{E}

Return a new `FroidurePin{E}` that is a copy of `fp` with element `x`
added as a generator (without checking containment).
"""
function copy_add_generators(fp::FroidurePin{E}, x::E) where {E}
    cxx_x = _cxx_element(x)
    new_cxx = @wrap_libsemigroups_call LibSemigroups.copy_add_generators(fp.cxx_obj, cxx_x)
    return FroidurePin{E}(new_cxx)
end

function copy_add_generators(fp::FroidurePin{BMat8}, x::BMat8)
    cxx_x = _cxx_element(x)
    new_cxx = @wrap_libsemigroups_call LibSemigroups.copy_add_generators(fp.cxx_obj, cxx_x)
    return FroidurePin{BMat8}(new_cxx)
end

"""
    reserve!(fp::FroidurePin, n::Integer) -> FroidurePin

Pre-allocate storage for at least `n` elements. This is a performance
hint and does not affect correctness.

Returns `fp` for method chaining.
"""
function reserve!(fp::FroidurePin, n::Integer)
    val = UInt(n)
    @wrap_libsemigroups_call LibSemigroups.reserve!(fp.cxx_obj, val)
    return fp
end

# ============================================================================
# Settings
# ============================================================================

"""
    batch_size(fp::FroidurePin) -> Int

Return the current value of the batch size.

The batch size is the minimum number of new elements to be found by any
call to [`run!`](@ref). This is used by, for example,
[`position`](@ref) so that it is possible to find the position of an
element after only partially enumerating the semigroup.

The default value of the batch size is `8192`.

# Complexity
Constant.

# See also
- [`set_batch_size!`](@ref)
"""
batch_size(fp::FroidurePin) = Int(LibSemigroups.batch_size(fp.cxx_obj))

"""
    set_batch_size!(fp::FroidurePin, n::Integer) -> FroidurePin

Set a new value for the batch size.

The *batch size* is the number of new elements to be found by any call
to [`run!`](@ref). This is used by, for example,
[`position`](@ref) so that it is possible to find the position of an
element after only partially enumerating the semigroup.

The default value of the batch size is `8192`.

Returns `fp` for method chaining.

# Arguments
- `fp::FroidurePin`: the FroidurePin instance.
- `n::Integer`: the new value for the batch size.

# Complexity
Constant.

# See also
- [`batch_size`](@ref)
"""
function set_batch_size!(fp::FroidurePin, n::Integer)
    LibSemigroups.set_batch_size!(fp.cxx_obj, UInt(n))
    return fp
end

# ============================================================================
# Predicates
# ============================================================================

"""
    contains_one(fp::FroidurePin) -> Bool

Check if the multiplicative identity is an element of `fp`.

This function returns `true` if the identity element (as returned by the
`One` adapter for the element type) is an element of the semigroup
represented by `fp`.

# Complexity
At worst ``O(|S| n)`` where ``S`` is the semigroup represented by `fp`
and ``n`` is the number of generators.

!!! note
    This function triggers a full enumeration.

# See also
- [`currently_contains_one`](@ref)
"""
contains_one(fp::FroidurePin) = LibSemigroups.contains_one(fp.cxx_obj)

"""
    is_idempotent(fp::FroidurePin, i::Integer) -> Bool

Check if the element at 1-based position `i` is an idempotent.

This function returns `true` if the element in position `i` is an
idempotent (i.e., `x * x == x`) and `false` if it is not.

# Arguments
- `fp::FroidurePin`: the FroidurePin instance.
- `i::Integer`: the 1-based index of the element.

# Throws
- `LibsemigroupsError`: if `i` is less than `1` or greater than the
  size of `fp`.

!!! note
    This function triggers a full enumeration.
"""
function is_idempotent(fp::FroidurePin, i::Integer)
    idx = _to_cpp(i, UInt)
    return @wrap_libsemigroups_call LibSemigroups.is_idempotent(fp.cxx_obj, idx)
end

# ============================================================================
# Index queries (FroidurePinBase methods — uint32_t positions)
# ============================================================================

"""
    prefix(fp::FroidurePin, i::Integer) -> Int

Return the position of the longest proper prefix.

This function returns the 1-based position of the prefix of the element
`x` at 1-based position `i`, where the prefix is the element of length
one less than `x` obtained by removing the last letter of the
factorisation.

For generators (elements of length 1), the prefix is
[`UNDEFINED`](@ref).

# Arguments
- `fp::FroidurePin`: the FroidurePin instance.
- `i::Integer`: the 1-based position of the element.

# Throws
- `LibsemigroupsError`: if `i` is less than `1` or greater than or
  equal to [`current_size`](@ref).

# Complexity
Constant.

!!! note
    This function does not trigger any enumeration.
"""
function prefix(fp::FroidurePin, i::Integer)
    idx = _to_cpp(i, UInt32)
    raw = @wrap_libsemigroups_call LibSemigroups.prefix(fp.cxx_obj, idx)
    return _from_cpp(raw)
end

"""
    suffix(fp::FroidurePin, i::Integer) -> Int

Return the position of the longest proper suffix.

This function returns the 1-based position of the suffix of the element
`x` at 1-based position `i`, where the suffix is the element of length
one less than `x` obtained by removing the first letter of the
factorisation.

For generators (elements of length 1), the suffix is
[`UNDEFINED`](@ref).

# Arguments
- `fp::FroidurePin`: the FroidurePin instance.
- `i::Integer`: the 1-based position of the element.

# Throws
- `LibsemigroupsError`: if `i` is less than `1` or greater than or
  equal to [`current_size`](@ref).

# Complexity
Constant.

!!! note
    This function does not trigger any enumeration.
"""
function suffix(fp::FroidurePin, i::Integer)
    idx = _to_cpp(i, UInt32)
    raw = @wrap_libsemigroups_call LibSemigroups.suffix(fp.cxx_obj, idx)
    return _from_cpp(raw)
end

"""
    first_letter(fp::FroidurePin, i::Integer) -> Int

Return the first letter of the element with specified index.

This function returns the 1-based index of the generator corresponding
to the first letter of the element in position `i`.

# Arguments
- `fp::FroidurePin`: the FroidurePin instance.
- `i::Integer`: the 1-based position of the element.

# Throws
- `LibsemigroupsError`: if `i` is less than `1` or greater than or
  equal to [`current_size`](@ref).

# Complexity
Constant.

!!! note
    `generator(fp, first_letter(fp, i))` is only equal to `fp[first_letter(fp, i)]`
    if there are no duplicate generators.

!!! note
    This function does not trigger any enumeration.
"""
function first_letter(fp::FroidurePin, i::Integer)
    idx = _to_cpp(i, UInt32)
    raw = @wrap_libsemigroups_call LibSemigroups.first_letter(fp.cxx_obj, idx)
    return _from_cpp(raw)
end

"""
    final_letter(fp::FroidurePin, i::Integer) -> Int

Return the last letter of the element with specified index.

This function returns the 1-based index of the generator corresponding
to the final letter of the element in position `i`.

# Arguments
- `fp::FroidurePin`: the FroidurePin instance.
- `i::Integer`: the 1-based position of the element.

# Throws
- `LibsemigroupsError`: if `i` is less than `1` or greater than or
  equal to [`current_size`](@ref).

# Complexity
Constant.

!!! note
    `generator(fp, final_letter(fp, i))` is only equal to `fp[final_letter(fp, i)]`
    if there are no duplicate generators.

!!! note
    This function does not trigger any enumeration.
"""
function final_letter(fp::FroidurePin, i::Integer)
    idx = _to_cpp(i, UInt32)
    raw = @wrap_libsemigroups_call LibSemigroups.final_letter(fp.cxx_obj, idx)
    return _from_cpp(raw)
end

"""
    fast_product(fp::FroidurePin, i::Integer, j::Integer) -> Int

Return the 1-based position of the product of the elements at 1-based
positions `i` and `j`.

The semigroup must be fully enumerated before calling this method.
"""
function fast_product(fp::FroidurePin, i::Integer, j::Integer)
    ci = _to_cpp(i, UInt)
    cj = _to_cpp(j, UInt)
    raw = @wrap_libsemigroups_call LibSemigroups.fast_product(fp.cxx_obj, ci, cj)
    return _from_cpp(raw)
end

"""
    number_of_rules(fp::FroidurePin) -> Int

Return the total number of rules (relations) in the semigroup.

Triggers full enumeration if not already complete.
"""
number_of_rules(fp::FroidurePin) = Int(LibSemigroups.number_of_rules(fp.cxx_obj))

"""
    current_number_of_rules(fp::FroidurePin) -> Int

Return the number of rules discovered so far (without triggering
further enumeration).
"""
current_number_of_rules(fp::FroidurePin) =
    Int(LibSemigroups.current_number_of_rules(fp.cxx_obj))

"""
    number_of_idempotents(fp::FroidurePin) -> Int

Return the total number of idempotent elements in the semigroup.

Triggers full enumeration if not already complete.
"""
number_of_idempotents(fp::FroidurePin) =
    Int(LibSemigroups.number_of_idempotents(fp.cxx_obj))

"""
    currently_contains_one(fp::FroidurePin) -> Bool

Check whether the identity element has been discovered so far
(without triggering further enumeration).
"""
currently_contains_one(fp::FroidurePin) = LibSemigroups.currently_contains_one(fp.cxx_obj)

"""
    current_max_word_length(fp::FroidurePin) -> Int

Return the maximum word length of elements enumerated so far
(without triggering further enumeration).
"""
current_max_word_length(fp::FroidurePin) =
    Int(LibSemigroups.current_max_word_length(fp.cxx_obj))

"""
    number_of_elements_of_length(fp::FroidurePin, len::Integer) -> Int

Return the number of elements whose minimal factorisation has
exactly length `len`.
"""
function number_of_elements_of_length(fp::FroidurePin, len::Integer)
    return Int(LibSemigroups.number_of_elements_of_length(fp.cxx_obj, UInt(len)))
end

"""
    number_of_elements_of_length(fp::FroidurePin, min::Integer, max::Integer) -> Int

Return the number of elements whose minimal factorisation has
length in the range `[min, max)`.
"""
function number_of_elements_of_length(fp::FroidurePin, min::Integer, max::Integer)
    return Int(
        LibSemigroups.number_of_elements_of_length_range(fp.cxx_obj, UInt(min), UInt(max)),
    )
end

"""
    position_of_generator(fp::FroidurePin, i::Integer) -> Int

Return the 1-based position of the `i`-th generator (1-based) in the
enumerated elements.
"""
function position_of_generator(fp::FroidurePin, i::Integer)
    idx = _to_cpp(i, UInt32)
    raw = @wrap_libsemigroups_call LibSemigroups.position_of_generator(fp.cxx_obj, idx)
    return _from_cpp(raw)
end

"""
    current_length(fp::FroidurePin, i::Integer) -> Int

Return the length of the minimal factorisation of the element at
1-based position `i` (without triggering further enumeration).
"""
function current_length(fp::FroidurePin, i::Integer)
    idx = _to_cpp(i, UInt32)
    raw = @wrap_libsemigroups_call LibSemigroups.current_length(fp.cxx_obj, idx)
    return Int(raw)
end

"""
    word_length(fp::FroidurePin, i::Integer) -> Int

Return the length of the minimal factorisation of the element at
1-based position `i`.

Triggers full enumeration if not already complete.

Named `word_length` to avoid conflict with `Base.length`.
"""
function word_length(fp::FroidurePin, i::Integer)
    idx = _to_cpp(i, UInt32)
    raw = @wrap_libsemigroups_call LibSemigroups.length(fp.cxx_obj, idx)
    return Int(raw)
end

"""
    product_by_reduction(fp::FroidurePin, i::Integer, j::Integer) -> Int

Return the 1-based position of the product of the elements at 1-based
positions `i` and `j`, computed using the Cayley graph (no full
enumeration required, but the elements at positions `i` and `j` must
already be enumerated).
"""
function product_by_reduction(fp::FroidurePin, i::Integer, j::Integer)
    ci = _to_cpp(i, UInt32)
    cj = _to_cpp(j, UInt32)
    raw = @wrap_libsemigroups_call LibSemigroups.product_by_reduction(fp.cxx_obj, ci, cj)
    return _from_cpp(raw)
end

# ============================================================================
# Collections — rules, normal forms, idempotents, sorted elements
# ============================================================================

"""
    rules(fp::FroidurePin) -> Vector{Pair{Vector{Int}, Vector{Int}}}

Return all defining rules of the semigroup as a vector of `lhs => rhs`
pairs, where each side is a 1-based generator-index word.

Triggers full enumeration if not already complete.

# Example
```julia
S = FroidurePin(Transf([2, 1, 3]), Transf([2, 3, 1]))
rs = rules(S)
for (lhs, rhs) in rs
    println(lhs, " => ", rhs)
end
```
"""
function rules(fp::FroidurePin)
    lhs_raw = @wrap_libsemigroups_call LibSemigroups.rules_lhs(fp.cxx_obj)
    rhs_raw = @wrap_libsemigroups_call LibSemigroups.rules_rhs(fp.cxx_obj)
    n = length(lhs_raw)
    result = Vector{Pair{Vector{Int},Vector{Int}}}(undef, n)
    for i = 1:n
        result[i] = _word_from_cpp(lhs_raw[i]) => _word_from_cpp(rhs_raw[i])
    end
    return result
end

"""
    current_rules(fp::FroidurePin) -> Vector{Pair{Vector{Int}, Vector{Int}}}

Return all rules discovered so far (without triggering further enumeration)
as a vector of `lhs => rhs` pairs with 1-based generator indices.
"""
function current_rules(fp::FroidurePin)
    lhs_raw = @wrap_libsemigroups_call LibSemigroups.current_rules_lhs(fp.cxx_obj)
    rhs_raw = @wrap_libsemigroups_call LibSemigroups.current_rules_rhs(fp.cxx_obj)
    n = length(lhs_raw)
    result = Vector{Pair{Vector{Int},Vector{Int}}}(undef, n)
    for i = 1:n
        result[i] = _word_from_cpp(lhs_raw[i]) => _word_from_cpp(rhs_raw[i])
    end
    return result
end

"""
    normal_forms(fp::FroidurePin) -> Vector{Vector{Int}}

Return the normal forms (canonical representatives) for all elements,
as 1-based generator-index words.

Triggers full enumeration if not already complete.
"""
function normal_forms(fp::FroidurePin)
    raw = @wrap_libsemigroups_call LibSemigroups.normal_forms(fp.cxx_obj)
    return [_word_from_cpp(w) for w in raw]
end

"""
    current_normal_forms(fp::FroidurePin) -> Vector{Vector{Int}}

Return the normal forms discovered so far (without triggering further
enumeration) as 1-based generator-index words.
"""
function current_normal_forms(fp::FroidurePin)
    raw = @wrap_libsemigroups_call LibSemigroups.current_normal_forms(fp.cxx_obj)
    return [_word_from_cpp(w) for w in raw]
end

"""
    idempotents(fp::FroidurePin{E}) -> Vector{E}

Return all idempotent elements of the semigroup (elements `x` such
that `x * x == x`).

Triggers full enumeration if not already complete.

# Example
```julia
S = FroidurePin(Transf([2, 1, 3]), Transf([2, 3, 1]))
ids = idempotents(S)  # [Transf([1, 2, 3])]
```
"""
function idempotents(fp::FroidurePin{E}) where {E}
    raw = @wrap_libsemigroups_call LibSemigroups.idempotents(fp.cxx_obj)
    # GC.@preserve raw to keep StdVector alive while iterating;
    # _copy_cxx_element converts Dereferenced refs to Allocated copies.
    GC.@preserve raw begin
        return E[_wrap_element(E, _copy_cxx_element(x)) for x in raw]
    end
end

"""
    sorted_elements(fp::FroidurePin{E}) -> Vector{E}

Return all elements of the semigroup in sorted order.

Triggers full enumeration if not already complete.

# Example
```julia
S = FroidurePin(Transf([2, 1, 3]), Transf([2, 3, 1]))
se = sorted_elements(S)
```
"""
function sorted_elements(fp::FroidurePin{E}) where {E}
    raw = @wrap_libsemigroups_call LibSemigroups.sorted_elements(fp.cxx_obj)
    # GC.@preserve raw to keep StdVector alive while iterating;
    # _copy_cxx_element converts Dereferenced refs to Allocated copies.
    GC.@preserve raw begin
        return E[_wrap_element(E, _copy_cxx_element(x)) for x in raw]
    end
end

# ============================================================================
# Factorisations
# ============================================================================

"""
    minimal_factorisation(fp::FroidurePin, i::Integer) -> Vector{Int}

Return the minimal factorisation of the element at 1-based position `i`
as a 1-based generator-index word.

# Example
```julia
S = FroidurePin(Transf([2, 1, 3]), Transf([2, 3, 1]))
w = minimal_factorisation(S, 1)  # [1] or [2] — a single generator
```
"""
function minimal_factorisation(fp::FroidurePin, i::Integer)
    idx = _to_cpp(i, UInt32)
    raw = @wrap_libsemigroups_call LibSemigroups.minimal_factorisation(fp.cxx_obj, idx)
    return _word_from_cpp(raw)
end

"""
    current_minimal_factorisation(fp::FroidurePin, i::Integer) -> Vector{Int}

Return the minimal factorisation of the element at 1-based position `i`
without triggering further enumeration.
"""
function current_minimal_factorisation(fp::FroidurePin, i::Integer)
    idx = _to_cpp(i, UInt32)
    raw = @wrap_libsemigroups_call LibSemigroups.current_minimal_factorisation(
        fp.cxx_obj,
        idx,
    )
    return _word_from_cpp(raw)
end

"""
    factorisation(fp::FroidurePin, i::Integer) -> Vector{Int}

Return the factorisation of the element at 1-based position `i`
as a 1-based generator-index word.

This may not be the minimal factorisation.
"""
function factorisation(fp::FroidurePin, i::Integer)
    idx = _to_cpp(i, UInt32)
    raw = @wrap_libsemigroups_call LibSemigroups.factorisation(fp.cxx_obj, idx)
    return _word_from_cpp(raw)
end

# ============================================================================
# Word-position queries
# ============================================================================

"""
    position(fp::FroidurePin, w::AbstractVector{<:Integer}) -> Int

Return the 1-based position of the element represented by the 1-based
generator-index word `w`.

Triggers full enumeration if not already complete.

# Example
```julia
S = FroidurePin(Transf([2, 1, 3]), Transf([2, 3, 1]))
position(S, [1])  # position of generator 1
```
"""
function position(fp::FroidurePin, w::AbstractVector{<:Integer})
    cw = _word_to_cpp(w)
    raw = @wrap_libsemigroups_call LibSemigroups.position(fp.cxx_obj, cw)
    return _from_cpp(raw)
end

# ============================================================================
# Cayley graphs
# ============================================================================

"""
    right_cayley_graph(fp::FroidurePin) -> WordGraph

Return the right Cayley graph of the semigroup.

Triggers full enumeration if not already complete.
"""
right_cayley_graph(fp::FroidurePin) = LibSemigroups.right_cayley_graph(fp.cxx_obj)

"""
    current_right_cayley_graph(fp::FroidurePin) -> WordGraph

Return the right Cayley graph for elements enumerated so far.
"""
current_right_cayley_graph(fp::FroidurePin) =
    LibSemigroups.current_right_cayley_graph(fp.cxx_obj)

"""
    left_cayley_graph(fp::FroidurePin) -> WordGraph

Return the left Cayley graph of the semigroup.

Triggers full enumeration if not already complete.
"""
left_cayley_graph(fp::FroidurePin) = LibSemigroups.left_cayley_graph(fp.cxx_obj)

"""
    current_left_cayley_graph(fp::FroidurePin) -> WordGraph

Return the left Cayley graph for elements enumerated so far.
"""
current_left_cayley_graph(fp::FroidurePin) =
    LibSemigroups.current_left_cayley_graph(fp.cxx_obj)

# ============================================================================
# Word-element conversion
# ============================================================================

"""
    to_element(fp::FroidurePin{E}, w::AbstractVector{<:Integer}) -> E

Convert a 1-based generator-index word `w` to the corresponding element.

# Example
```julia
S = FroidurePin(Transf([2, 1, 3]), Transf([2, 3, 1]))
x = to_element(S, [1, 2])  # product of generators 1 and 2
```
"""
function to_element(fp::FroidurePin{E}, w::AbstractVector{<:Integer}) where {E}
    cw = _word_to_cpp(w)
    raw = @wrap_libsemigroups_call LibSemigroups.to_element(fp.cxx_obj, cw)
    return _wrap_element(E, raw)
end

"""
    equal_to(fp::FroidurePin, w1::AbstractVector{<:Integer}, w2::AbstractVector{<:Integer}) -> Bool

Check whether two 1-based generator-index words represent the same element.

# Example
```julia
S = FroidurePin(Transf([2, 1, 3]), Transf([2, 3, 1]))
equal_to(S, [1, 1], [1])  # does gen1*gen1 == gen1?
```
"""
function equal_to(
    fp::FroidurePin,
    w1::AbstractVector{<:Integer},
    w2::AbstractVector{<:Integer},
)
    cw1 = _word_to_cpp(w1)
    cw2 = _word_to_cpp(w2)
    return @wrap_libsemigroups_call LibSemigroups.equal_to(fp.cxx_obj, cw1, cw2)
end
