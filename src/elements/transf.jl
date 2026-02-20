# Copyright (c) 2026, James W. Swent, J. D. Mitchell
#
# Distributed under the terms of the GPL license version 3.
#
# The full license is in the file LICENSE, distributed with this software.

"""
transf.jl - High-level Julia API for transformations

This file provides user-facing transformation types (Transf, PPerm, Perm)
with idiomatic Julia interfaces: 1-based indexing, automatic type selection,
and standard Julia operators.
"""

using CxxWrap.StdLib: StdVector

# ============================================================================
# Type selection helpers (shared by all transformation types)
# ============================================================================

"""
    _scalar_type_from_degree(n::Integer) -> Type

Select appropriate unsigned integer type based on degree `n`.
Returns UInt8 for n ≤ 255, UInt16 for n ≤ 65535, UInt32 otherwise.
"""
function _scalar_type_from_degree(n::Integer)
    # Use <= for typemax: degree n stores 0-based indices 0..n-1, so max index n-1
    # must fit in the scalar type. For n=255, max index=254 fits in UInt8.
    if n <= typemax(UInt8)
        return UInt8
    elseif n <= typemax(UInt16)
        return UInt16
    elseif n <= typemax(UInt32)
        return UInt32
    else
        error("Degree $n too large (maximum supported degree is 2^32-1)")
    end
end

"""
    _transf_type_from_degree(n::Integer) -> Type

Select appropriate Transf type (Transf1, Transf2, or Transf4) based on degree.
"""
function _transf_type_from_degree(n::Integer)
    T = _scalar_type_from_degree(n)
    if T === UInt8
        return Transf1
    elseif T === UInt16
        return Transf2
    else
        return Transf4
    end
end

function _transf_type_from_scalar_type(scalar::DataType)
    lookup = Dict(UInt8 => Transf1, UInt16 => Transf2, UInt32 => Transf4)
    return lookup[scalar]
end

function _pperm_type_from_scalar_type(scalar::DataType)
    lookup = Dict(UInt8 => PPerm1, UInt16 => PPerm2, UInt32 => PPerm4)
    return lookup[scalar]
end

function _perm_type_from_scalar_type(scalar::DataType)
    lookup = Dict(UInt8 => Perm1, UInt16 => Perm2, UInt32 => Perm4)
    return lookup[scalar]
end

"""
    _pperm_type_from_degree(n::Integer) -> Type

Select appropriate PPerm type (PPerm1, PPerm2, or PPerm4) based on degree.
"""
function _pperm_type_from_degree(n::Integer)
    T = _scalar_type_from_degree(n)
    if T === UInt8
        return PPerm1
    elseif T === UInt16
        return PPerm2
    else
        return PPerm4
    end
end

"""
    _perm_type_from_degree(n::Integer) -> Type

Select appropriate Perm type (Perm1, Perm2, or Perm4) based on degree.
"""
function _perm_type_from_degree(n::Integer)
    T = _scalar_type_from_degree(n)
    if T === UInt8
        return Perm1
    elseif T === UInt16
        return Perm2
    else
        return Perm4
    end
end

# ============================================================================
# Transf - Full transformations
# ============================================================================

"""
    Transf{T}

Transformations with dynamic degree.

A *transformation* ``f`` is just a function defined on the whole of
``\\{1, 2, \\ldots, n\\}`` for some integer ``n`` called the *degree*
of ``f``. A transformation is stored as a vector of the images of
``\\{1, 2, \\ldots, n\\}``, i.e. ``((1)f, (2)f, \\ldots, (n)f)``.

# Construction

```julia
using Semigroups

# From an image list
t = Transf([2, 1, 2, 3])  # maps 1->2, 2->1, 3->2, 4->3
t[1]  # 2
t[3]  # 2
```
"""
mutable struct Transf{T}
    cxx_obj::Union{Transf1,Transf2,Transf4}
end

Transf(t::Transf1) = Transf{UInt8}(t)
Transf(t::Transf2) = Transf{UInt16}(t)
Transf(t::Transf4) = Transf{UInt32}(t)

"""
    Transf(images::AbstractVector{<:Integer}, ::Type{T}) where {T}

Construct a [`Transf`](@ref) from a container of images with explicit
scalar type `T`.

The image of the point `i` under the transformation is the value
in position `i` of `images`.

# Example
```julia
using Semigroups

t = Transf([2, 1, 2, 3], UInt8)
t[1]  # 2
```

# Throws
- `LibsemigroupsError` if any value in `images` exceeds
  `length(images)`.
"""
function Transf(images::AbstractVector{<:Integer}, ::Type{T}) where {T}
    n = length(images)
    if n == 0 || n > typemax(T)
        error("Cannot create transformation of degree $n")
    end

    CxxType = _transf_type_from_scalar_type(T)
    images_typed = convert(Vector{T}, images)
    cxx_obj = @wrap_libsemigroups_call CxxType(StdVector{T}(images_typed))
    return Transf{T}(cxx_obj)
end

"""
    Transf(images::AbstractVector{<:Integer})

Construct a [`Transf`](@ref) from a container of images.

The image of the point `i` under the transformation is the value
in position `i` of `images`. The scalar type is selected automatically
based on the degree.

# Example
```julia
using Semigroups

t = Transf([2, 1, 2, 3])
t[1]  # 2
```

# Throws
- `LibsemigroupsError` if any value in `images` exceeds
  `length(images)`.
"""
function Transf(images::AbstractVector{<:Integer})
    return Transf(images, _scalar_type_from_degree(length(images)))
end

# Degree and rank
"""
    degree(t::Transf) -> Int

Returns the degree of a transformation.

The _degree_ of a transformation is the number of points used in its
definition, which is equal to the size of its underlying container.

# Example
```jldoctest
julia> using Semigroups

julia> t = Transf([2, 3, 1, 4]);

julia> degree(t)
4
```
"""
degree(t::Transf) = degree(t.cxx_obj)

"""
    rank(t::Transf) -> Int

Returns the number of distinct image values of a transformation.

The _rank_ of a transformation is the number of its distinct image
values.

# Example
```jldoctest
julia> using Semigroups

julia> rank(Transf([1, 1, 1]))
1

julia> rank(Transf([2, 3, 1]))
3
```

# Complexity
Linear in [`degree()`](@ref Semigroups.degree(::Transf))
"""
rank(t::Transf) = rank(t.cxx_obj)

# Indexing (1-based for Julia)
"""
    getindex(t::Transf, i::Integer) -> Int

Returns the image of the point `i` under transformation `t`.

# Example
```jldoctest
julia> using Semigroups

julia> t = Transf([2, 3, 1]);

julia> t[1]
2

julia> t[3]
1
```

# Throws
- `BoundsError` if `i` is out of range.

# Complexity
Constant.
"""
function Base.getindex(t::Transf, i::Integer)
    if i < 1 || i > degree(t)
        throw(BoundsError(t, i))
    end
    return Int(LibSemigroups.getindex(t.cxx_obj, UInt(i)))
end

# Iteration
"""
    iterate(t::Transf, [state])

Iterate over the images of transformation `t`. Returns 1-based indices.
"""
function Base.iterate(t::Transf, state = 1)
    if state > degree(t)
        return nothing
    end
    return (t[state], state + 1)
end

Base.length(t::Transf) = degree(t)

# Comparison operators
# Call the named C++ comparison methods
Base.:(==)(t1::Transf, t2::Transf) = LibSemigroups.is_equal(t1.cxx_obj, t2.cxx_obj)
Base.:(<)(t1::Transf, t2::Transf) = LibSemigroups.is_less(t1.cxx_obj, t2.cxx_obj)
Base.:(<=)(t1::Transf, t2::Transf) = LibSemigroups.is_less_equal(t1.cxx_obj, t2.cxx_obj)
Base.:(>)(t1::Transf, t2::Transf) = LibSemigroups.is_greater(t1.cxx_obj, t2.cxx_obj)
Base.:(>=)(t1::Transf, t2::Transf) = LibSemigroups.is_greater_equal(t1.cxx_obj, t2.cxx_obj)

# Hash
Base.hash(t::Transf, h::UInt) = hash(hash_value(t.cxx_obj), h)

# Copy
"""
    Base.copy(t::Transf) -> Transf

Create an independent copy of transformation `t`.

# Example
```jldoctest
julia> using Semigroups

julia> t = Transf([2, 3, 1]);

julia> s = copy(t);

julia> t == s
true
```
"""
Base.copy(t::Transf{T}) where {T} = Transf{T}(copy(t.cxx_obj))

# Multiplication
"""
    *(t1::Transf, t2::Transf) -> Transf

Compose two transformations. Returns t1 ∘ t2, i.e., (t1*t2)[i] = t1[t2[i]].
Both operands must have the same scalar type (use the same underlying C++ type).

# Example
```jldoctest
julia> using Semigroups

julia> s = Transf([2, 1, 3]);

julia> t = Transf([3, 2, 1]);

julia> s * t
Transf([2, 3, 1])
```
"""
function Base.:(*)(t1::Transf{T}, t2::Transf{T}) where {T}
    result_cxx = one(t1.cxx_obj)
    product_inplace!(result_cxx, t1.cxx_obj, t2.cxx_obj)
    return Transf(result_cxx)
end

# Display
function Base.show(io::IO, t::Transf)
    imgs = [t[i] for i = 1:degree(t)]
    if degree(t) <= 10
        print(io, "Transf(", imgs, ")")
    else
        print(io, "<transformation of degree ", degree(t), " and rank ", rank(t), ">")
    end
end

"""
    Base.one(::Type{Transf}, n::Integer) -> Transf

Returns the identity transformation on _n_ points.

This function returns a newly constructed transformation with degree equal to _n_
that fixes every value from `1` to _n_.

# Example
```jldoctest
julia> using Semigroups

julia> one(Transf, 3)
Transf([1, 2, 3])
```
"""
function Base.one(::Type{Transf}, n::Integer)
    CxxType = _transf_type_from_degree(n)
    return Transf(LibSemigroups.one(CxxType, UInt(n)))
end

# ============================================================================
# PPerm - Partial permutations
# ============================================================================

"""
    PPerm{T}

Partial permutations with dynamic degree.

A *partial permutation* ``f`` is just an injective partial transformation,
which is stored as a vector of the images of ``\\{1, 2, \\ldots, n\\}``,
i.e. ``((1)f, (2)f, \\ldots, (n)f)`` where the value [`UNDEFINED`](@ref)
is used to indicate that ``(i)f`` is undefined (i.e. not among the
points where ``f`` is defined).

# Construction

```julia
using Semigroups

# From an image list (use UNDEFINED for undefined points)
p = PPerm([2, UNDEFINED, 1])
p[1]  # 2
p[2]  # UNDEFINED

# From domain, image, and degree
p = PPerm([1, 3], [2, 1], 3)  # 1 -> 2, 3 -> 1, degree 3
```
"""
mutable struct PPerm{T}
    cxx_obj::Union{PPerm1,PPerm2,PPerm4}
end

PPerm(p::PPerm1) = PPerm{UInt8}(p)
PPerm(p::PPerm2) = PPerm{UInt16}(p)
PPerm(p::PPerm4) = PPerm{UInt32}(p)

"""
    PPerm(images::AbstractVector, ::Type{T}) where {T}

Construct a [`PPerm`](@ref) from a container of images with explicit
scalar type `T`.

The image of the point `i` under the partial permutation is the value
in position `i` of `images`. Use [`UNDEFINED`](@ref) to indicate that
a point is undefined.

# Example
```julia
using Semigroups

p = PPerm([2, UNDEFINED, 1, 4], UInt8)
p[2]  # UNDEFINED
```

# Throws
- `LibsemigroupsError` if any value in `images` exceeds
  `length(images)` and is not equal to [`UNDEFINED`](@ref).
"""
function PPerm(images::AbstractVector, ::Type{T}) where {T}
    n = length(images)
    if n == 0
        error("Cannot create partial permutation of degree 0")
    end

    CxxType = _pperm_type_from_scalar_type(T)

    images_typed = Vector{T}(undef, n)
    for (i, img) in enumerate(images)
        if img isa Integer && img <= 0
            throw(
                ArgumentError(
                    "expected a positive integer or UNDEFINED, found $img in position $i",
                ),
            )
        end
        images_typed[i] = convert(T, img)  # UNDEFINED → T(0), integers → T(img)
    end

    cxx_obj = @wrap_libsemigroups_call CxxType(StdVector{T}(images_typed))
    return PPerm{T}(cxx_obj)
end

"""
    PPerm(images::AbstractVector)

Construct a [`PPerm`](@ref) from a container of images.

The image of the point `i` under the partial permutation is the value
in position `i` of `images`. Use [`UNDEFINED`](@ref) to indicate that
a point is undefined. The scalar type is selected automatically based
on the degree.

# Example
```julia
using Semigroups

p = PPerm([2, UNDEFINED, 1, 4])
p[2]  # UNDEFINED
```

# Throws
- `LibsemigroupsError` if any value in `images` exceeds
  `length(images)` and is not equal to [`UNDEFINED`](@ref).
"""
function PPerm(images::AbstractVector)
    return PPerm(images, _scalar_type_from_degree(length(images)))
end

"""
    PPerm(domain::AbstractVector{<:Integer}, image::AbstractVector{<:Integer}, deg::Integer, ::Type{T}) where {T}

Construct a [`PPerm`](@ref) from domain, range, and degree with explicit
scalar type `T`.

Constructs a partial permutation of degree `deg` such that `p[domain[i]] =
image[i]` for all `i` and which is [`UNDEFINED`](@ref) on every other value
in the range ``[1, deg]``.

# Example
```julia
using Semigroups

p = PPerm([1, 3], [2, 4], 5, UInt8)  # 1 -> 2, 3 -> 4, degree 5
```

# Throws
- `LibsemigroupsError` if `domain` and `image` do not have the same
  size, any value in `domain` or `image` is greater than `deg`, or there
  are repeated entries in `domain` or `image`.
"""
function PPerm(
    domain::AbstractVector{<:Integer},
    image::AbstractVector{<:Integer},
    deg::Integer,
    ::Type{T},
) where {T}
    if length(domain) != length(image)
        error("Domain and image must have the same length")
    end

    CxxType = _pperm_type_from_scalar_type(T)

    dom_typed = convert(Vector{T}, domain)
    img_typed = convert(Vector{T}, image)

    cxx_obj = @wrap_libsemigroups_call CxxType(
        StdVector{T}(dom_typed),
        StdVector{T}(img_typed),
        UInt(deg),
    )
    return PPerm{T}(cxx_obj)
end

"""
    PPerm(domain::AbstractVector{<:Integer}, image::AbstractVector{<:Integer}, deg::Integer)

Construct a [`PPerm`](@ref) from domain, range, and degree.

Constructs a partial permutation of degree `deg` such that `p[domain[i]] =
image[i]` for all `i` and which is [`UNDEFINED`](@ref) on every other value
in the range ``[1, deg]``. The scalar type is selected automatically based
on `deg`.

# Example
```julia
using Semigroups

p = PPerm([1, 3], [2, 4], 5)  # 1 -> 2, 3 -> 4, degree 5
```

# Throws
- `LibsemigroupsError` if `domain` and `image` do not have the same
  size, any value in `domain` or `image` is greater than `deg`, or there
  are repeated entries in `domain` or `image`.
"""
function PPerm(
    domain::AbstractVector{<:Integer},
    image::AbstractVector{<:Integer},
    deg::Integer,
)
    return PPerm(domain, image, deg, _scalar_type_from_degree(deg))
end

"""
    degree(p::PPerm) -> Int

Returns the degree of a partial permutation.

The _degree_ of a partial permutation is the number of points used in its
definition, which is equal to the size of its underlying container.

# Example
```jldoctest
julia> using Semigroups

julia> degree(PPerm([1, 3], [2, 4], 5))
5
```
"""
degree(p::PPerm) = degree(p.cxx_obj)

"""
    rank(p::PPerm) -> Int

Returns the number of distinct image values in a partial permutation.

The _rank_ of a partial permutation is the number of its distinct image
values, not including [`UNDEFINED`](@ref).

# Example
```jldoctest
julia> using Semigroups

julia> rank(PPerm([1, 3], [2, 4], 5))
2
```

# Complexity
Linear in [`degree()`](@ref Semigroups.degree(::PPerm))
"""
rank(p::PPerm) = rank(p.cxx_obj)

# Indexing (1-based, returns UNDEFINED if not defined)
"""
    getindex(p::PPerm, i::Integer) -> Union{Int, UndefinedType}

Get the image of point `i` under partial permutation `p`.
Returns [`UNDEFINED`](@ref) if `i` is not in the domain.

# Example
```jldoctest
julia> using Semigroups

julia> p = PPerm([1, 3], [2, 4], 5);

julia> p[1]
2

julia> p[2]
UNDEFINED
```

# Throws
- `BoundsError` if `i` is out of range.
"""
function Base.getindex(p::PPerm, i::Integer)
    if i < 1 || i > degree(p)
        throw(BoundsError(p, i))
    end
    # C++ binding returns 0 for undefined points (via to_1_based_undef)
    result = LibSemigroups.getindex(p.cxx_obj, UInt(i))
    return result == 0 ? UNDEFINED : Int(result)
end

# Iteration
function Base.iterate(p::PPerm, state = 1)
    if state > degree(p)
        return nothing
    end
    return (p[state], state + 1)
end

Base.length(p::PPerm) = degree(p)

# Comparison operators
Base.:(==)(p1::PPerm, p2::PPerm) = LibSemigroups.is_equal(p1.cxx_obj, p2.cxx_obj)
Base.:(<)(p1::PPerm, p2::PPerm) = LibSemigroups.is_less(p1.cxx_obj, p2.cxx_obj)
Base.:(<=)(p1::PPerm, p2::PPerm) = LibSemigroups.is_less_equal(p1.cxx_obj, p2.cxx_obj)
Base.:(>)(p1::PPerm, p2::PPerm) = LibSemigroups.is_greater(p1.cxx_obj, p2.cxx_obj)
Base.:(>=)(p1::PPerm, p2::PPerm) = LibSemigroups.is_greater_equal(p1.cxx_obj, p2.cxx_obj)

# Hash
Base.hash(p::PPerm, h::UInt) = hash(hash_value(p.cxx_obj), h)

# Copy
"""
    Base.copy(p::PPerm) -> PPerm

Create an independent copy of partial permutation `p`.

# Example
```jldoctest
julia> using Semigroups

julia> p = PPerm([1, 3], [2, 4], 5);

julia> q = copy(p);

julia> p == q
true
```
"""
Base.copy(p::PPerm{T}) where {T} = PPerm{T}(copy(p.cxx_obj))

# Multiplication
"""
    *(p1::PPerm, p2::PPerm) -> PPerm

Compose two partial permutations.
Both operands must have the same scalar type (use the same underlying C++ type).

# Example
```jldoctest
julia> using Semigroups

julia> p = PPerm([1, 2], [3, 4], 5);

julia> q = PPerm([3, 4], [5, 1], 5);

julia> p * q
PPerm([1, 2], [5, 1], 5)
```
"""
function Base.:(*)(p1::PPerm{T}, p2::PPerm{T}) where {T}
    result_cxx = one(p1.cxx_obj)
    product_inplace!(result_cxx, p1.cxx_obj, p2.cxx_obj)
    return PPerm(result_cxx)
end

# Display
function Base.show(io::IO, p::PPerm)
    dom = domain(p)
    if degree(p) <= 10
        imgs = [p[i] for i in dom]
        print(io, "PPerm(", dom, ", ", imgs, ", ", degree(p), ")")
    else
        print(io, "<partial perm of degree ", degree(p), " and rank ", rank(p), ">")
    end
end

"""
    Base.inv(p::PPerm) -> PPerm

Return the inverse of partial permutation `p`.

# Example
```jldoctest
julia> using Semigroups

julia> p = PPerm([1, 2], [3, 4], 5);

julia> q = inv(p);

julia> p * q == left_one(p)
true

julia> q * p == right_one(p)
true
```
"""
function Base.inv(p::PPerm)
    return PPerm(inverse(p.cxx_obj))
end

"""
    left_one(p::PPerm) -> PPerm

Returns the left one of a partial permutation.

This function returns a newly constructed partial permutation with degree
equal to that of _p_ that fixes every value in the domain of _p_,
and is [`UNDEFINED`](@ref) on any other values.

# Example
```jldoctest
julia> using Semigroups

julia> p = PPerm([1, 3], [2, 4], 4);

julia> left_one(p) * p == p
true
```
"""
left_one(p::PPerm) = PPerm(left_one(p.cxx_obj))

"""
    right_one(p::PPerm) -> PPerm

Returns the right one of a partial permutation.

This function returns a newly constructed partial permutation with degree
equal to that of _p_ that fixes every value in the image of _p_, and is
[`UNDEFINED`](@ref) on any other values.

# Example
```jldoctest
julia> using Semigroups

julia> p = PPerm([1, 3], [2, 4], 4);

julia> p * right_one(p) == p
true
```
"""
right_one(p::PPerm) = PPerm(right_one(p.cxx_obj))

"""
    Base.one(::Type{PPerm}, n::Integer) -> PPerm

Returns the identity partial permutation on _n_ points.

This function returns a newly constructed partial permutation with degree
equal to _n_ that fixes every value from `1` to _n_.

# Example
```jldoctest
julia> using Semigroups

julia> one(PPerm, 3)
PPerm([1, 2, 3], [1, 2, 3], 3)
```
"""
function Base.one(::Type{PPerm}, n::Integer)
    CxxType = _pperm_type_from_degree(n)
    return PPerm(LibSemigroups.one(CxxType, UInt(n)))
end

# ============================================================================
# Perm - Permutations
# ============================================================================

"""
    Perm{T}

Permutations with dynamic degree.

A *permutation* ``f`` is an injective transformation defined on the
whole of ``\\{1, 2, \\ldots, n\\}`` for some integer ``n`` called
the *degree* of ``f``. A permutation is stored as a vector of the
images of ``\\{1, 2, \\ldots, n\\}``, i.e.
``((1)f, (2)f, \\ldots, (n)f)``.

# Construction

```julia
using Semigroups

# From an image list
p = Perm([2, 3, 1])  # maps 1->2, 2->3, 3->1
p[1]  # 2
p[2]  # 3
```
"""
mutable struct Perm{T}
    cxx_obj::Union{Perm1,Perm2,Perm4}
end

Perm(p::Perm1) = Perm{UInt8}(p)
Perm(p::Perm2) = Perm{UInt16}(p)
Perm(p::Perm4) = Perm{UInt32}(p)

"""
    Perm(images::AbstractVector{<:Integer}, ::Type{T}) where {T}

Construct a [`Perm`](@ref) from a container of images with explicit
scalar type `T`.

The image of the point `i` under the permutation is the value in
position `i` of `images`.

# Example
```julia
using Semigroups

p = Perm([2, 3, 1], UInt8)
p[1]  # 2
```

# Throws
- `ErrorException` if any value in `images` exceeds `length(images)`
  or there are repeated values in `images`.
"""
function Perm(images::AbstractVector{<:Integer}, ::Type{T}) where {T}
    n = length(images)
    if n == 0
        error("Cannot create permutation of degree 0")
    end

    if !isperm(images)
        error(
            "Input is not a valid permutation (must be a bijection from {1,...,n} to {1,...,n})",
        )
    end

    CxxType = _perm_type_from_scalar_type(T)
    images_typed = convert(Vector{T}, images)
    cxx_obj = @wrap_libsemigroups_call CxxType(StdVector{T}(images_typed))
    return Perm{T}(cxx_obj)
end

"""
    Perm(images::AbstractVector{<:Integer})

Construct a [`Perm`](@ref) from a container of images.

The image of the point `i` under the permutation is the value in
position `i` of `images`. The scalar type is selected automatically
based on the degree.

# Example
```julia
using Semigroups

p = Perm([2, 3, 1])
p[1]  # 2
```

# Throws
- `ErrorException` if any value in `images` exceeds `length(images)`
  or there are repeated values in `images`.
"""
function Perm(images::AbstractVector{<:Integer})
    return Perm(images, _scalar_type_from_degree(length(images)))
end

# Helper to check if vector is a permutation
function isperm(v::AbstractVector{<:Integer})
    n = length(v)
    seen = falses(n)
    for x in v
        if x < 1 || x > n
            return false
        end
        if seen[x]
            return false
        end
        seen[x] = true
    end
    return all(seen)
end

# Degree and rank
"""
    degree(p::Perm) -> Int

Returns the degree of a permutation.

The _degree_ of a permutation is the number of points used in its
definition, which is equal to the size of its underlying container.

# Example
```jldoctest
julia> using Semigroups

julia> degree(Perm([2, 3, 1]))
3
```
"""
degree(p::Perm) = degree(p.cxx_obj)

"""
    rank(p::Perm) -> Int

Returns the number of distinct image values of a permutation.

The _rank_ of a permutation is the number of its distinct image
values, not including [`UNDEFINED`](@ref).

# Example
```jldoctest
julia> using Semigroups

julia> rank(Perm([2, 3, 1]))
3
```

# Complexity
Linear in [`degree()`](@ref Semigroups.degree(::Perm))
"""
rank(p::Perm) = rank(p.cxx_obj)

# Indexing (1-based)
"""
    getindex(p::Perm, i::Integer) -> Int

Returns the image of the point `i` under permutation `p`.

# Example
```jldoctest
julia> using Semigroups

julia> p = Perm([2, 3, 1]);

julia> p[1]
2

julia> p[3]
1
```

# Throws
- `BoundsError` if `i` is out of range.

# Complexity
Constant.
"""
function Base.getindex(p::Perm, i::Integer)
    if i < 1 || i > degree(p)
        throw(BoundsError(p, i))
    end
    return Int(LibSemigroups.getindex(p.cxx_obj, UInt(i)))
end

# Iteration
function Base.iterate(p::Perm, state = 1)
    if state > degree(p)
        return nothing
    end
    return (p[state], state + 1)
end

Base.length(p::Perm) = degree(p)

# Comparison operators
Base.:(==)(p1::Perm, p2::Perm) = LibSemigroups.is_equal(p1.cxx_obj, p2.cxx_obj)
Base.:(<)(p1::Perm, p2::Perm) = LibSemigroups.is_less(p1.cxx_obj, p2.cxx_obj)
Base.:(<=)(p1::Perm, p2::Perm) = LibSemigroups.is_less_equal(p1.cxx_obj, p2.cxx_obj)
Base.:(>)(p1::Perm, p2::Perm) = LibSemigroups.is_greater(p1.cxx_obj, p2.cxx_obj)
Base.:(>=)(p1::Perm, p2::Perm) = LibSemigroups.is_greater_equal(p1.cxx_obj, p2.cxx_obj)

# Hash
Base.hash(p::Perm, h::UInt) = hash(hash_value(p.cxx_obj), h)

# Copy
"""
    Base.copy(p::Perm) -> Perm

Create an independent copy of permutation `p`.

# Example
```jldoctest
julia> using Semigroups

julia> p = Perm([2, 3, 1]);

julia> q = copy(p);

julia> p == q
true
```
"""
Base.copy(p::Perm{T}) where {T} = Perm{T}(copy(p.cxx_obj))

# Multiplication
"""
    *(p1::Perm, p2::Perm) -> Perm

Compose two permutations.
Both operands must have the same scalar type (use the same underlying C++ type).

# Example
```jldoctest
julia> using Semigroups

julia> p = Perm([2, 3, 1]);

julia> q = Perm([3, 1, 2]);

julia> p * q
Perm([1, 2, 3])
```
"""
function Base.:(*)(p1::Perm{T}, p2::Perm{T}) where {T}
    result_cxx = one(p1.cxx_obj)
    product_inplace!(result_cxx, p1.cxx_obj, p2.cxx_obj)
    return Perm(result_cxx)
end

# Display
function Base.show(io::IO, p::Perm)
    imgs = [p[i] for i = 1:degree(p)]
    if degree(p) <= 10
        print(io, "Perm(", imgs, ")")
    else
        print(io, "<permutation of degree ", degree(p), ">")
    end
end

# Perm-specific methods

"""
    Base.one(::Type{Perm}, n::Integer) -> Perm

Returns the identity permutation on _n_ points.

This function returns a newly constructed permutation with degree
equal to _n_ that fixes every value from `1` to _n_.

# Example
```jldoctest
julia> using Semigroups

julia> one(Perm, 3)
Perm([1, 2, 3])
```
"""
function Base.one(::Type{Perm}, n::Integer)
    CxxType = _perm_type_from_degree(n)
    return Perm(LibSemigroups.one(CxxType, UInt(n)))
end

# ============================================================================
# Generic functions for multiple types
# ============================================================================

"""
    image(f::Union{Transf, PPerm, Perm}) -> Vector{Int}

Return the sorted set of image values of a partial transformation.

Returns a vector containing those values `f[i]` such that
``i \\in \\{1, \\ldots, n\\}`` where ``n`` is the [`degree`](@ref) of
`f`, and `f[i] != UNDEFINED`.

# Complexity
``O(n \\log n)`` where ``n`` is the [`degree`](@ref) of `f`.

See also [`domain`](@ref).

# Example
```jldoctest
julia> using Semigroups

julia> image(Transf([2, 2, 1]))
2-element Vector{Int64}:
 1
 2

julia> image(PPerm([1, 3], [2, 4], 5))
2-element Vector{Int64}:
 2
 4
```
"""
image(f::Union{Transf,PPerm,Perm}) = sort([Int(x) for x in image(f.cxx_obj)])

"""
    domain(f::Union{Transf, PPerm, Perm}) -> Vector{Int}

Return the sorted set of points where a partial transformation is defined.

Returns a vector containing those values ``i`` such that
``i \\in \\{1, \\ldots, n\\}`` where ``n`` is the [`degree`](@ref) of
`f`, and `f[i] != UNDEFINED`.

# Complexity
``O(n)`` where ``n`` is the [`degree`](@ref) of `f`.

See also [`image`](@ref).

# Example
```jldoctest
julia> using Semigroups

julia> domain(Transf([2, 2, 1]))
3-element Vector{Int64}:
 1
 2
 3

julia> domain(PPerm([1, 3], [2, 4], 5))
2-element Vector{Int64}:
 1
 3
```
"""
domain(f::Union{Transf,PPerm,Perm}) = sort([Int(x) for x in domain(f.cxx_obj)])

"""
    increase_degree_by!(t::Union{Transf,PPerm,Perm}, n::Integer)

Increase the degree of transformation `t` by `n` points.
Modifies `t` in place, leaving existing values unaltered.

# Example
```jldoctest
julia> using Semigroups

julia> t = Transf([1, 2]);

julia> increase_degree_by!(t, 3);

julia> degree(t)
5
```
"""
function increase_degree_by!(t::Union{Transf,PPerm,Perm}, n::Integer)
    increase_degree_by!(t.cxx_obj, n)
    return t
end

"""
    inverse(p::T) where T<:Union{PPerm,Perm} -> T

Returns the inverse of a partial permutation or permutation.

This function returns a newly constructed inverse of _p_. The _inverse_
of a partial permutation _p_ is the partial term `g` such that
`fgf = f` and `gfg =g`.

# Example
```jldoctest
julia> using Semigroups

julia> p = Perm([2, 3, 1]);

julia> inverse(p)
Perm([3, 1, 2])

julia> p * inverse(p) == one(Perm, 3)
true
```
"""
function inverse(p::T) where {T<:Union{PPerm,Perm}}
    return T(inverse(p.cxx_obj))
end

"""
    Base.one(p::T) where T<:Union{Transf,PPerm,Perm} -> T

Returns the identity on the same number of points as the degree of _p_.

This function returns a newly constructed object of the same type as
_p_ that fixes every value from `1` to `degree(p)`.

# Example
```jldoctest
julia> using Semigroups

julia> p = Perm([2, 3, 1]);

julia> one(p)
Perm([1, 2, 3])

julia> p * one(p) == p
true
```
"""
function Base.one(p::T) where {T<:Union{Transf,PPerm,Perm}}
    return T(one(p.cxx_obj))
end

"""
    swap!(t1::T, t2::T) where T<:Union{Transf,PPerm,Perm}

Swap the contents of transformations `t1` and `t2`. Both objects are modified.

# Example
```julia
t1 = Transf([1, 2])
t2 = Transf([2, 1, 3])
swap!(t1, t2)  # t1 and t2 have exchanged contents
```
"""
function swap!(t1::T, t2::T) where {T<:Union{Transf,PPerm,Perm}}
    swap!(t1.cxx_obj, t2.cxx_obj)
    return nothing
end
