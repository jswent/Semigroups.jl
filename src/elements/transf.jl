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
    Transf

A transformation is a function from {1, 2, ..., n} to itself.
The transformation is represented by a vector of images.

# Construction
```julia
# Create transformation [1, 2, 1] (maps 1->1, 2->2, 3->1)
t = Transf([1, 2, 1])
```

Note: The constructor accepts 1-based indexing (Julia convention) but
internally converts to 0-based indexing for the C++ library.
"""
mutable struct Transf{T}
    cxx_obj::Union{Transf1,Transf2,Transf4}

    """
        Transf(images::AbstractVector{<:Integer})

    Create a transformation from a vector of images using 1-based indexing.
    The degree is the length of the vector.

    # Example
    ```julia
    t = Transf([2, 1, 2, 3])  # degree 4, maps 1->2, 2->1, 3->2, 4->3
    ```
    """
    # Internal constructor from C++ object (used by operations)
    # function Transf(cxx_obj::Union{Transf1,Transf2,Transf4})
    #   return new{typeof(cxx_obj)}(cxx_obj)
    # end

end

Transf(t::Transf1) = Transf{UInt8}(t)
Transf(t::Transf2) = Transf{UInt16}(t)
Transf(t::Transf4) = Transf{UInt32}(t)

function Transf(images::AbstractVector{<:Integer}, ::Type{T}) where {T}
    n = length(images)
    if n == 0 || n > typemax(T)
        error("Cannot create transformation of degree $n")
    end

    # Select the appropriate C++ type based on T
    CxxType = _transf_type_from_scalar_type(T)

    # Convert to 0-based indexing for C++
    images_0based = [UInt(img - 1) for img in images]

    # Convert to the desired type T
    images_typed = convert(Vector{T}, images_0based)

    # Construct the C++ object (StdVector wrapper)
    cxx_obj = @wrap_libsemigroups_call CxxType(StdVector{T}(images_typed))

    # Return the Transf{T} instance
    return Transf{T}(cxx_obj)
end

function Transf(images::AbstractVector{<:Integer})
    return Transf(images, _scalar_type_from_degree(length(images)))
end

# Degree and rank
"""
    degree(t::Transf) -> Int

Return the degree of transformation `t` (the size of its domain).
"""
degree(t::Transf) = degree(t.cxx_obj)

"""
    rank(t::Transf) -> Int

Return the rank of transformation `t` (the size of its image).
"""
rank(t::Transf) = rank(t.cxx_obj)

# Indexing (1-based for Julia)
"""
    getindex(t::Transf, i::Integer) -> Int

Get the image of point `i` under transformation `t`. Uses 1-based indexing.

# Example
```julia
t = Transf([2, 1, 2])
t[1]  # Returns 2
t[3]  # Returns 2
```
"""
function Base.getindex(t::Transf, i::Integer)
    if i < 1 || i > degree(t)
        throw(BoundsError(t, i))
    end
    # Convert to 0-based, call C++, convert back to 1-based
    return Int(LibSemigroups.getindex(t.cxx_obj, UInt(i - 1))) + 1
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
    copy(t::Transf) -> Transf

Create an independent copy of transformation `t`.
"""
Base.copy(t::Transf{T}) where {T} = Transf{T}(copy(t.cxx_obj))

# Multiplication
"""
    *(t1::Transf, t2::Transf) -> Transf

Compose two transformations. Returns t1 ∘ t2, i.e., (t1*t2)[i] = t1[t2[i]].
"""
function Base.:(*)(t1::Transf, t2::Transf)
    # Promote to larger type if needed
    max_deg = max(degree(t1), degree(t2))
    CxxType = _transf_type_from_degree(max_deg)

    # Create identity of appropriate type
    result_cxx = LibSemigroups.one(CxxType, UInt(max_deg))

    # Promote operands if needed
    t1_cxx = t1.cxx_obj
    t2_cxx = t2.cxx_obj

    if typeof(t1_cxx) !== CxxType
        imgs1 = [UInt(img) for img in images_vector(t1_cxx)]
        while length(imgs1) < max_deg
            push!(imgs1, UInt(length(imgs1)))
        end
        ScalarType = CxxType === Transf1 ? UInt8 : (CxxType === Transf2 ? UInt16 : UInt32)
        # Convert Julia Vector to CxxWrap StdVector
        std_vec1 = StdVector{ScalarType}(convert(Vector{ScalarType}, imgs1))
        t1_cxx = @wrap_libsemigroups_call CxxType(std_vec1)
    end

    if typeof(t2_cxx) !== CxxType
        imgs2 = [UInt(img) for img in images_vector(t2_cxx)]
        while length(imgs2) < max_deg
            push!(imgs2, UInt(length(imgs2)))
        end
        ScalarType = CxxType === Transf1 ? UInt8 : (CxxType === Transf2 ? UInt16 : UInt32)
        # Convert Julia Vector to CxxWrap StdVector
        std_vec2 = StdVector{ScalarType}(convert(Vector{ScalarType}, imgs2))
        t2_cxx = @wrap_libsemigroups_call CxxType(std_vec2)
    end

    # Compute product
    product_inplace!(result_cxx, t1_cxx, t2_cxx)

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

# Additional methods
"""
    images(t::Transf) -> Vector{Int}

Return the vector of all images of `t` using 1-based indexing.
"""
images(t::Transf) = [t[i] for i = 1:degree(t)]

"""
    image_set(t::Transf) -> Vector{Int}

Return a sorted vector of all distinct values in the image of `t`.
Uses 1-based indexing.
"""
function image_set(t::Transf)
    # Get image from C++ (0-based)
    img_0based = image(t.cxx_obj)
    # Convert to 1-based
    return sort([Int(x) + 1 for x in img_0based])
end

"""
    Base.one(t::Transf) -> Transf

Return the identity transformation with the same degree as `t`.
"""
function Base.one(t::Transf)
    return Transf(one(t.cxx_obj))
end

"""
    Base.one(::Type{Transf}, n::Integer) -> Transf

Return the identity transformation of degree `n`.
"""
function Base.one(::Type{Transf}, n::Integer)
    CxxType = _transf_type_from_degree(n)
    return Transf(LibSemigroups.one(CxxType, UInt(n)))
end

# ============================================================================
# PPerm - Partial permutations
# ============================================================================

"""
    PPerm

A partial permutation is an injective partial function from {1, 2, ..., n} to itself.
Undefined points are represented by the special value UNDEFINED.

# Construction
```julia
# From images with UNDEFINED
p = PPerm([2, UNDEFINED, 1])  # maps 1->2, 2->undefined, 3->1

# From domain, image, and degree
p = PPerm([1, 3], [2, 1], 3)  # maps 1->2, 3->1, degree 3
```
"""
mutable struct PPerm
    cxx_obj::Union{PPerm1,PPerm2,PPerm4}

    """
        PPerm(images::AbstractVector)

    Create a partial permutation from a vector of images using 1-based indexing.
    Use UNDEFINED for undefined points.

    # Example
    ```julia
    using Semigroups: UNDEFINED
    p = PPerm([2, UNDEFINED, 1, 4])  # 2 is not in the domain
    ```
    """
    function PPerm(images::AbstractVector)
        n = length(images)
        if n == 0
            error("Cannot create partial permutation of degree 0")
        end

        # Convert to 0-based indexing for C++
        ScalarType =
            _scalar_type_from_degree(n) == UInt8 ? UInt8 :
            (_scalar_type_from_degree(n) == UInt16 ? UInt16 : UInt32)

        images_0based = Vector{ScalarType}(undef, n)
        for (i, img) in enumerate(images)
            if img === UNDEFINED
                images_0based[i] = convert(ScalarType, UNDEFINED)
            else
                images_0based[i] = ScalarType(img - 1)
            end
        end

        # Select appropriate C++ type based on degree
        CxxType = _pperm_type_from_degree(n)

        # Construct C++ object - CxxWrap needs StdVector
        cxx_obj = @wrap_libsemigroups_call CxxType(StdVector(images_0based))

        return new(cxx_obj)
    end

    """
        PPerm(domain::AbstractVector{<:Integer}, image::AbstractVector{<:Integer}, degree::Integer)

    Create a partial permutation from domain and image vectors with specified degree.
    Uses 1-based indexing.

    # Example
    ```julia
    p = PPerm([1, 3], [2, 4], 5)  # maps 1->2, 3->4, degree 5
    ```
    """
    function PPerm(
        domain::AbstractVector{<:Integer},
        image::AbstractVector{<:Integer},
        deg::Integer,
    )
        if length(domain) != length(image)
            error("Domain and image must have the same length")
        end

        # Convert to 0-based
        ScalarType =
            _scalar_type_from_degree(deg) == UInt8 ? UInt8 :
            (_scalar_type_from_degree(deg) == UInt16 ? UInt16 : UInt32)

        dom_0based = convert(Vector{ScalarType}, [ScalarType(d - 1) for d in domain])
        img_0based = convert(Vector{ScalarType}, [ScalarType(i - 1) for i in image])

        # Select appropriate C++ type
        CxxType = _pperm_type_from_degree(deg)

        # Construct C++ object - CxxWrap needs StdVector
        cxx_obj = @wrap_libsemigroups_call CxxType(
            StdVector(dom_0based),
            StdVector(img_0based),
            UInt(deg),
        )

        return new(cxx_obj)
    end

    # Internal constructor from C++ object
    function PPerm(cxx_obj::Union{PPerm1,PPerm2,PPerm4})
        return new(cxx_obj)
    end
end

# Degree and rank
degree(p::PPerm) = degree(p.cxx_obj)
rank(p::PPerm) = rank(p.cxx_obj)

# Indexing (1-based, returns UNDEFINED if not defined)
"""
    getindex(p::PPerm, i::Integer) -> Union{Int, UndefinedType}

Get the image of point `i` under partial permutation `p`.
Returns UNDEFINED if `i` is not in the domain.
Uses 1-based indexing.
"""
function Base.getindex(p::PPerm, i::Integer)
    if i < 1 || i > degree(p)
        throw(BoundsError(p, i))
    end
    # Convert to 0-based, call C++
    result_0based = LibSemigroups.getindex(p.cxx_obj, UInt(i - 1))

    # Check if UNDEFINED
    ScalarType = typeof(result_0based)
    if result_0based == convert(ScalarType, UNDEFINED)
        return UNDEFINED
    else
        return Int(result_0based) + 1
    end
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
Base.copy(p::PPerm) = PPerm(copy(p.cxx_obj))

# Multiplication
function Base.:(*)(p1::PPerm, p2::PPerm)
    max_deg = max(degree(p1), degree(p2))
    CxxType = _pperm_type_from_degree(max_deg)

    result_cxx = LibSemigroups.one(CxxType, UInt(max_deg))

    # Type promotion logic similar to Transf
    p1_cxx = p1.cxx_obj
    p2_cxx = p2.cxx_obj

    if typeof(p1_cxx) !== CxxType
        imgs1 = images_vector(p1_cxx)
        ScalarType = CxxType === PPerm1 ? UInt8 : (CxxType === PPerm2 ? UInt16 : UInt32)
        while length(imgs1) < max_deg
            push!(imgs1, convert(ScalarType, UNDEFINED))
        end
        # Convert Julia Vector to CxxWrap StdVector
        std_vec1 = StdVector{ScalarType}(convert(Vector{ScalarType}, imgs1))
        p1_cxx = @wrap_libsemigroups_call CxxType(std_vec1)
    end

    if typeof(p2_cxx) !== CxxType
        imgs2 = images_vector(p2_cxx)
        ScalarType = CxxType === PPerm1 ? UInt8 : (CxxType === PPerm2 ? UInt16 : UInt32)
        while length(imgs2) < max_deg
            push!(imgs2, convert(ScalarType, UNDEFINED))
        end
        # Convert Julia Vector to CxxWrap StdVector
        std_vec2 = StdVector{ScalarType}(convert(Vector{ScalarType}, imgs2))
        p2_cxx = @wrap_libsemigroups_call CxxType(std_vec2)
    end

    product_inplace!(result_cxx, p1_cxx, p2_cxx)

    return PPerm(result_cxx)
end

# Display
function Base.show(io::IO, p::PPerm)
    dom = domain_set(p)
    if degree(p) <= 10
        imgs = [p[i] for i in dom]
        print(io, "PPerm(", dom, ", ", imgs, ", ", degree(p), ")")
    else
        print(io, "<partial perm of degree ", degree(p), " and rank ", rank(p), ">")
    end
end

# PPerm-specific methods
"""
    domain_set(p::PPerm) -> Vector{Int}

Return a sorted vector of all points in the domain of `p` (where p is defined).
Uses 1-based indexing.
"""
function domain_set(p::PPerm)
    dom_0based = domain(p.cxx_obj)
    return sort([Int(x) + 1 for x in dom_0based])
end

"""
    image_set(p::PPerm) -> Vector{Int}

Return a sorted vector of all points in the image of `p`.
Uses 1-based indexing.
"""
function image_set(p::PPerm)
    img_0based = image(p.cxx_obj)
    return sort([Int(x) + 1 for x in img_0based])
end

"""
    Base.inv(p::PPerm) -> PPerm

Return the inverse of partial permutation `p`.
"""
function Base.inv(p::PPerm)
    return PPerm(inverse(p.cxx_obj))
end

"""
    left_one(p::PPerm) -> PPerm

Return the partial permutation that acts as identity on the domain of `p`.
"""
left_one(p::PPerm) = PPerm(left_one(p.cxx_obj))

"""
    right_one(p::PPerm) -> PPerm

Return the partial permutation that acts as identity on the image of `p`.
"""
right_one(p::PPerm) = PPerm(right_one(p.cxx_obj))

"""
    Base.one(p::PPerm) -> PPerm

Return the identity partial permutation with the same degree as `p`.
"""
function Base.one(p::PPerm)
    return PPerm(one(p.cxx_obj))
end

function Base.one(::Type{PPerm}, n::Integer)
    CxxType = _pperm_type_from_degree(n)
    return PPerm(LibSemigroups.one(CxxType, UInt(n)))
end

# ============================================================================
# Perm - Permutations
# ============================================================================

"""
    Perm

A permutation is a bijective function from {1, 2, ..., n} to itself.

# Construction
```julia
# Create permutation [2, 3, 1] (maps 1->2, 2->3, 3->1)
p = Perm([2, 3, 1])
```

The constructor validates that the input is a valid permutation.
"""
mutable struct Perm
    cxx_obj::Union{Perm1,Perm2,Perm4}

    """
        Perm(images::AbstractVector{<:Integer})

    Create a permutation from a vector of images using 1-based indexing.
    Validates that the input is a bijection.

    # Example
    ```julia
    p = Perm([2, 3, 1])  # Valid: bijection from {1,2,3} to {1,2,3}
    p = Perm([1, 1, 2])  # Error: not a bijection
    ```
    """
    function Perm(images::AbstractVector{<:Integer})
        n = length(images)
        if n == 0
            error("Cannot create permutation of degree 0")
        end

        # Validate that it's a permutation (bijection)
        if !isperm(images)
            error(
                "Input is not a valid permutation (must be a bijection from {1,...,n} to {1,...,n})",
            )
        end

        # Convert to 0-based indexing for C++
        images_0based = [UInt(img - 1) for img in images]

        # Select appropriate C++ type based on degree
        CxxType = _perm_type_from_degree(n)
        ScalarType = CxxType === Perm1 ? UInt8 : (CxxType === Perm2 ? UInt16 : UInt32)

        # Convert to correct scalar type
        images_typed = convert(Vector{ScalarType}, images_0based)

        # Construct C++ object - CxxWrap needs StdVector
        cxx_obj = @wrap_libsemigroups_call CxxType(StdVector(images_typed))

        return new(cxx_obj)
    end

    # Internal constructor from C++ object
    function Perm(cxx_obj::Union{Perm1,Perm2,Perm4})
        return new(cxx_obj)
    end
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
degree(p::Perm) = degree(p.cxx_obj)
rank(p::Perm) = rank(p.cxx_obj)  # Always equals degree for permutations

# Indexing (1-based)
function Base.getindex(p::Perm, i::Integer)
    if i < 1 || i > degree(p)
        throw(BoundsError(p, i))
    end
    return Int(LibSemigroups.getindex(p.cxx_obj, UInt(i - 1))) + 1
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
Base.copy(p::Perm) = Perm(copy(p.cxx_obj))

# Multiplication
function Base.:(*)(p1::Perm, p2::Perm)
    max_deg = max(degree(p1), degree(p2))
    CxxType = _perm_type_from_degree(max_deg)

    result_cxx = LibSemigroups.one(CxxType, UInt(max_deg))

    # Type promotion
    p1_cxx = p1.cxx_obj
    p2_cxx = p2.cxx_obj

    if typeof(p1_cxx) !== CxxType
        imgs1 = [UInt(img) for img in images_vector(p1_cxx)]
        while length(imgs1) < max_deg
            push!(imgs1, UInt(length(imgs1)))
        end
        ScalarType = CxxType === Perm1 ? UInt8 : (CxxType === Perm2 ? UInt16 : UInt32)
        # Convert Julia Vector to CxxWrap StdVector
        std_vec1 = StdVector{ScalarType}(convert(Vector{ScalarType}, imgs1))
        p1_cxx = @wrap_libsemigroups_call CxxType(std_vec1)
    end

    if typeof(p2_cxx) !== CxxType
        imgs2 = [UInt(img) for img in images_vector(p2_cxx)]
        while length(imgs2) < max_deg
            push!(imgs2, UInt(length(imgs2)))
        end
        ScalarType = CxxType === Perm1 ? UInt8 : (CxxType === Perm2 ? UInt16 : UInt32)
        # Convert Julia Vector to CxxWrap StdVector
        std_vec2 = StdVector{ScalarType}(convert(Vector{ScalarType}, imgs2))
        p2_cxx = @wrap_libsemigroups_call CxxType(std_vec2)
    end

    product_inplace!(result_cxx, p1_cxx, p2_cxx)

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
    Base.inv(p::Perm) -> Perm

Return the inverse of permutation `p`.
"""
function Base.inv(p::Perm)
    return Perm(inverse(p.cxx_obj))
end

"""
    Base.one(p::Perm) -> Perm

Return the identity permutation with the same degree as `p`.
"""
function Base.one(p::Perm)
    return Perm(one(p.cxx_obj))
end

function Base.one(::Type{Perm}, n::Integer)
    CxxType = _perm_type_from_degree(n)
    return Perm(LibSemigroups.one(CxxType, UInt(n)))
end

"""
    images(p::Perm) -> Vector{Int}

Return the vector of all images of `p` using 1-based indexing.
"""
images(p::Perm) = [p[i] for i = 1:degree(p)]

"""
    image_set(p::Perm) -> Vector{Int}

Return a sorted vector of all distinct values in the image of `p`.
For permutations, this is always [1, 2, ..., degree(p)].
Uses 1-based indexing.
"""
function image_set(p::Perm)
    # Get image from C++ (0-based)
    img_0based = image(p.cxx_obj)
    # Convert to 1-based
    return sort([Int(x) + 1 for x in img_0based])
end

# ============================================================================
# Generic functions for all transformation types
# ============================================================================

"""
    increase_degree_by!(t::Union{Transf,PPerm,Perm}, n::Integer)

Increase the degree of transformation `t` by `n` points.
Modifies `t` in place and returns it for method chaining.

# Example
```julia
t = Transf([1, 2])
increase_degree_by!(t, 3)  # Now has degree 5
```
"""
function increase_degree_by!(t::Union{Transf,PPerm,Perm}, n::Integer)
    increase_degree_by!(t.cxx_obj, n)
    return t
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
