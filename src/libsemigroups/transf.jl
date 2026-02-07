# Copyright (c) 2026, James W. Swent, J. D. Mitchell
#
# Distributed under the terms of the GPL license version 3.
#
# The full license is in the file LICENSE, distributed with this software.

"""
transf.jl - Julia wrappers for libsemigroups transformation classes

This file provides low-level Julia wrappers for the C++ transformation
classes (Transf, PPerm, Perm) exposed via CxxWrap. These are thin wrappers
that provide memory safety via GC.@preserve and convenient access to the
C++ bindings.
"""

# ============================================================================
# Type aliases - Concrete template instantiations from C++
# ============================================================================

"""
    Transf1

Transformation with uint8_t scalar type (supports degrees up to 2^8 = 256).
This is the underlying C++ type Transf<0, uint8_t>.
"""
const Transf1 = LibSemigroups.Transf1

"""
    Transf2

Transformation with uint16_t scalar type (supports degrees up to 2^16 = 65536).
This is the underlying C++ type Transf<0, uint16_t>.
"""
const Transf2 = LibSemigroups.Transf2

"""
    Transf4

Transformation with uint32_t scalar type (supports degrees up to 2^32).
This is the underlying C++ type Transf<0, uint32_t>.
"""
const Transf4 = LibSemigroups.Transf4

"""
    PPerm1

Partial permutation with uint8_t scalar type (supports degrees up to 2^8 = 256).
This is the underlying C++ type PPerm<0, uint8_t>.
"""
const PPerm1 = LibSemigroups.PPerm1

"""
    PPerm2

Partial permutation with uint16_t scalar type (supports degrees up to 2^16 = 65536).
This is the underlying C++ type PPerm<0, uint16_t>.
"""
const PPerm2 = LibSemigroups.PPerm2

"""
    PPerm4

Partial permutation with uint32_t scalar type (supports degrees up to 2^32).
This is the underlying C++ type PPerm<0, uint32_t>.
"""
const PPerm4 = LibSemigroups.PPerm4

"""
    Perm1

Permutation with uint8_t scalar type (supports degrees up to 2^8 = 256).
This is the underlying C++ type Perm<0, uint8_t>.
"""
const Perm1 = LibSemigroups.Perm1

"""
    Perm2

Permutation with uint16_t scalar type (supports degrees up to 2^16 = 65536).
This is the underlying C++ type Perm<0, uint16_t>.
"""
const Perm2 = LibSemigroups.Perm2

"""
    Perm4

Permutation with uint32_t scalar type (supports degrees up to 2^32).
This is the underlying C++ type Perm<0, uint32_t>.
"""
const Perm4 = LibSemigroups.Perm4

# Union types for generic functions (for internal use in this file)
const _TransfTypes = Union{Transf1,Transf2,Transf4}
const _PPermTypes = Union{PPerm1,PPerm2,PPerm4}
const _PermTypes = Union{Perm1,Perm2,Perm4}
const _PTransfTypes = Union{_TransfTypes,_PPermTypes,_PermTypes}

# ============================================================================
# Instance methods - Direct wrappers
# ============================================================================

"""
    degree(t) -> Int

Return the degree of the transformation, i.e., the number of points in its domain.
"""
degree(t::_PTransfTypes) = Int(LibSemigroups.degree(t))

"""
    rank(t) -> Int

Return the rank of the transformation, i.e., the number of distinct values in its image.
"""
rank(t::_PTransfTypes) = Int(LibSemigroups.rank(t))

"""
    hash_value(t) -> UInt

Return the hash value of the transformation.
"""
hash_value(t::_PTransfTypes) = LibSemigroups.hash(t)

"""
    images_vector(t) -> Vector

Return a vector containing all image values of the transformation.
For PPerm, undefined points are represented by UNDEFINED.
"""
images_vector(t::_PTransfTypes) = LibSemigroups.images_vector(t)

# ============================================================================
# Methods requiring GC.@preserve for memory safety
# ============================================================================

"""
    product_inplace!(result::T, x::T, y::T) where T

Compute the product of `x` and `y` and store the result in `result`.
This modifies `result` in place. The result is equivalent to `result = x * y`.

Returns `nothing` (modifies `result` in place).

# Example
```julia
result = Transf1([0, 0, 0])
x = Transf1([1, 0, 1])
y = Transf1([0, 1, 0])
product_inplace!(result, x, y)
# result now contains x * y
```
"""
function product_inplace!(result::T, x::T, y::T) where {T<:_PTransfTypes}
    GC.@preserve result x y begin
        @wrap_libsemigroups_call LibSemigroups.product_inplace!(result, x, y)
    end
    return nothing
end

"""
    increase_degree_by!(t::T, n::Integer) where T -> T

Increase the degree of transformation `t` by `n`.
This modifies `t` in place and returns `t` for method chaining.

# Example
```julia
t = Transf1([1, 0])
increase_degree_by!(t, 2)  # Now has degree 4
```
"""
function increase_degree_by!(t::T, n::Integer) where {T<:_PTransfTypes}
    GC.@preserve t begin
        @wrap_libsemigroups_call LibSemigroups.increase_degree_by!(t, UInt(n))
    end
    return t
end

"""
    swap!(t::T, x::T) where T

Swap the contents of `t` with `x`. Both objects are modified.
"""
function swap!(t::T, x::T) where {T<:_PTransfTypes}
    GC.@preserve t x begin
        @wrap_libsemigroups_call LibSemigroups.swap(t, x)
    end
    return nothing
end

"""
    copy(t)

Create a copy of the transformation `t`.
"""
function copy(t::_PTransfTypes)
    return LibSemigroups.copy(t)
end

# ============================================================================
# Module-level helper functions
# ============================================================================

"""
    one(t)

Return the identity transformation with the same degree as `t`.
"""
one(t::_PTransfTypes) = LibSemigroups.one(t)

"""
    one(::Type{T}, n::Integer) where T

Return the identity transformation of type `T` with degree `n`.
"""
one(::Type{Transf1}, n::Integer) = LibSemigroups.one(Transf1, UInt(n))
one(::Type{Transf2}, n::Integer) = LibSemigroups.one(Transf2, UInt(n))
one(::Type{Transf4}, n::Integer) = LibSemigroups.one(Transf4, UInt(n))
one(::Type{PPerm1}, n::Integer) = LibSemigroups.one(PPerm1, UInt(n))
one(::Type{PPerm2}, n::Integer) = LibSemigroups.one(PPerm2, UInt(n))
one(::Type{PPerm4}, n::Integer) = LibSemigroups.one(PPerm4, UInt(n))
one(::Type{Perm1}, n::Integer) = LibSemigroups.one(Perm1, UInt(n))
one(::Type{Perm2}, n::Integer) = LibSemigroups.one(Perm2, UInt(n))
one(::Type{Perm4}, n::Integer) = LibSemigroups.one(Perm4, UInt(n))

"""
    image(t) -> Vector

Return a sorted vector of all points in the image of the transformation.
For partial transformations (PPerm), only defined image points are included.
"""
image(t::_PTransfTypes) = LibSemigroups.image(t)

"""
    domain(t) -> Vector

Return a sorted vector of all points in the domain of the transformation.
For full transformations (Transf, Perm), this is `[0, 1, ..., degree(t)-1]`.
For partial transformations (PPerm), only defined domain points are included.
"""
domain(t::_PTransfTypes) = LibSemigroups.domain(t)

"""
    inverse(p)

Return the inverse of the partial permutation or permutation `p`.
For PPerm, returns the inverse partial permutation.
For Perm, returns the inverse permutation.

Note: Not available for general transformations (Transf) as they may not be invertible.
"""
inverse(p::Union{_PPermTypes,_PermTypes}) = LibSemigroups.inverse(p)

"""
    left_one(p)

Return the partial permutation that acts as the identity on the domain of `p`.
This is the partial permutation that maps each point in `domain(p)` to itself.
"""
left_one(p::_PPermTypes) = LibSemigroups.left_one(p)

"""
    right_one(p)

Return the partial permutation that acts as the identity on the image of `p`.
This is the partial permutation that maps each point in `image(p)` to itself.
"""
right_one(p::_PPermTypes) = LibSemigroups.right_one(p)
