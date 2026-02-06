# Copyright (c) 2026, James W. Swent
#
# Distributed under the terms of the GPL license version 3.
#
# The full license is in the file LICENSE, distributed with this software.

"""
constants.jl - Julia wrappers for libsemigroups constants

This file provides Julia-friendly access to the libsemigroups constants
UNDEFINED, POSITIVE_INFINITY, NEGATIVE_INFINITY, and LIMIT_MAX.
"""

# Singleton types for special constants
# These allow us to dispatch on the constant type while providing
# type-specific conversions to integer values.

struct UndefinedType end

"""
    UNDEFINED

Represents an undefined value in libsemigroups. Can be compared with
any integer type using `==` and `!=`. Converts to the maximum value
of the target integer type.
"""
const UNDEFINED = UndefinedType()

struct PositiveInfinityType end

"""
    POSITIVE_INFINITY

Represents positive infinity in libsemigroups. Can be compared with
integers and NEGATIVE_INFINITY using `<`, `>`, `==`, `!=`. Converts
to max-1 of the target integer type.
"""
const POSITIVE_INFINITY = PositiveInfinityType()

struct NegativeInfinityType end

"""
    NEGATIVE_INFINITY

Represents negative infinity in libsemigroups. Can be compared with
signed integers and POSITIVE_INFINITY using `<`, `>`, `==`, `!=`.
Converts to the minimum value of the target signed integer type.
"""
const NEGATIVE_INFINITY = NegativeInfinityType()

struct LimitMaxType end

"""
    LIMIT_MAX

Represents the maximum limit value in libsemigroups. Converts to
max-2 of the target integer type.
"""
const LIMIT_MAX = LimitMaxType()

# Conversion functions to get the underlying integer values

# UNDEFINED conversions
Base.convert(::Type{UInt8}, ::UndefinedType) = LibSemigroups.UNDEFINED_UInt8()
Base.convert(::Type{UInt16}, ::UndefinedType) = LibSemigroups.UNDEFINED_UInt16()
Base.convert(::Type{UInt32}, ::UndefinedType) = LibSemigroups.UNDEFINED_UInt32()
Base.convert(::Type{UInt64}, ::UndefinedType) = LibSemigroups.UNDEFINED_UInt64()
Base.convert(::Type{Int64}, ::UndefinedType) = LibSemigroups.UNDEFINED_Int64()

# POSITIVE_INFINITY conversions
Base.convert(::Type{UInt8}, ::PositiveInfinityType) =
    LibSemigroups.POSITIVE_INFINITY_UInt8()
Base.convert(::Type{UInt16}, ::PositiveInfinityType) =
    LibSemigroups.POSITIVE_INFINITY_UInt16()
Base.convert(::Type{UInt32}, ::PositiveInfinityType) =
    LibSemigroups.POSITIVE_INFINITY_UInt32()
Base.convert(::Type{UInt64}, ::PositiveInfinityType) =
    LibSemigroups.POSITIVE_INFINITY_UInt64()
Base.convert(::Type{Int64}, ::PositiveInfinityType) =
    LibSemigroups.POSITIVE_INFINITY_Int64()

# NEGATIVE_INFINITY conversions (signed types only)
Base.convert(::Type{Int8}, ::NegativeInfinityType) = LibSemigroups.NEGATIVE_INFINITY_Int8()
Base.convert(::Type{Int16}, ::NegativeInfinityType) =
    LibSemigroups.NEGATIVE_INFINITY_Int16()
Base.convert(::Type{Int32}, ::NegativeInfinityType) =
    LibSemigroups.NEGATIVE_INFINITY_Int32()
Base.convert(::Type{Int64}, ::NegativeInfinityType) =
    LibSemigroups.NEGATIVE_INFINITY_Int64()

# LIMIT_MAX conversions
Base.convert(::Type{UInt8}, ::LimitMaxType) = LibSemigroups.LIMIT_MAX_UInt8()
Base.convert(::Type{UInt16}, ::LimitMaxType) = LibSemigroups.LIMIT_MAX_UInt16()
Base.convert(::Type{UInt32}, ::LimitMaxType) = LibSemigroups.LIMIT_MAX_UInt32()
Base.convert(::Type{UInt64}, ::LimitMaxType) = LibSemigroups.LIMIT_MAX_UInt64()
Base.convert(::Type{Int64}, ::LimitMaxType) = LibSemigroups.LIMIT_MAX_Int64()

# Comparison operations

# UNDEFINED comparisons (equality only)
Base.:(==)(x::Integer, ::UndefinedType) = x == convert(typeof(x), UNDEFINED)
Base.:(==)(::UndefinedType, x::Integer) = convert(typeof(x), UNDEFINED) == x
Base.:(==)(::UndefinedType, ::UndefinedType) = true
Base.:(==)(::UndefinedType, ::PositiveInfinityType) = false
Base.:(==)(::UndefinedType, ::NegativeInfinityType) = false
Base.:(==)(::UndefinedType, ::LimitMaxType) = false

# POSITIVE_INFINITY comparisons
Base.:(==)(x::Integer, ::PositiveInfinityType) = x == convert(typeof(x), POSITIVE_INFINITY)
Base.:(==)(::PositiveInfinityType, x::Integer) = convert(typeof(x), POSITIVE_INFINITY) == x
Base.:(==)(::PositiveInfinityType, ::PositiveInfinityType) = true
Base.:(==)(::PositiveInfinityType, ::UndefinedType) = false
Base.:(==)(::PositiveInfinityType, ::NegativeInfinityType) = false
Base.:(==)(::PositiveInfinityType, ::LimitMaxType) = false

Base.:(<)(::PositiveInfinityType, ::Integer) = false
Base.:(<)(x::Integer, ::PositiveInfinityType) = true
Base.:(<)(::NegativeInfinityType, ::PositiveInfinityType) = true
Base.:(<)(::PositiveInfinityType, ::NegativeInfinityType) = false
Base.:(<)(::PositiveInfinityType, ::PositiveInfinityType) = false

# NEGATIVE_INFINITY comparisons
Base.:(==)(x::Integer, ::NegativeInfinityType) = x == convert(typeof(x), NEGATIVE_INFINITY)
Base.:(==)(::NegativeInfinityType, x::Integer) = convert(typeof(x), NEGATIVE_INFINITY) == x
Base.:(==)(::NegativeInfinityType, ::NegativeInfinityType) = true
Base.:(==)(::NegativeInfinityType, ::UndefinedType) = false
Base.:(==)(::NegativeInfinityType, ::PositiveInfinityType) = false
Base.:(==)(::NegativeInfinityType, ::LimitMaxType) = false

Base.:(<)(::NegativeInfinityType, x::Integer) = true
Base.:(<)(x::Integer, ::NegativeInfinityType) = false
Base.:(<)(::NegativeInfinityType, ::NegativeInfinityType) = false

# LIMIT_MAX comparisons
Base.:(==)(x::Integer, ::LimitMaxType) = x == convert(typeof(x), LIMIT_MAX)
Base.:(==)(::LimitMaxType, x::Integer) = convert(typeof(x), LIMIT_MAX) == x
Base.:(==)(::LimitMaxType, ::LimitMaxType) = true
Base.:(==)(::LimitMaxType, ::UndefinedType) = false
Base.:(==)(::LimitMaxType, ::PositiveInfinityType) = false
Base.:(==)(::LimitMaxType, ::NegativeInfinityType) = false

Base.:(<)(::LimitMaxType, x::Integer) = convert(typeof(x), LIMIT_MAX) < x
Base.:(<)(x::Integer, ::LimitMaxType) = x < convert(typeof(x), LIMIT_MAX)

# Helper functions to check if a value is a special constant

"""
    is_undefined(x::Integer, T::Type = typeof(x))

Check if `x` equals UNDEFINED for the given integer type `T`.
"""
is_undefined(x::Integer, ::Type{T} = typeof(x)) where {T<:Integer} =
    x == convert(T, UNDEFINED)

"""
    is_positive_infinity(x::Integer, T::Type = typeof(x))

Check if `x` equals POSITIVE_INFINITY for the given integer type `T`.
"""
is_positive_infinity(x::Integer, ::Type{T} = typeof(x)) where {T<:Integer} =
    x == convert(T, POSITIVE_INFINITY)

"""
    is_negative_infinity(x::Integer, T::Type = typeof(x))

Check if `x` equals NEGATIVE_INFINITY for the given signed integer type `T`.
"""
is_negative_infinity(x::Signed, ::Type{T} = typeof(x)) where {T<:Signed} =
    x == convert(T, NEGATIVE_INFINITY)

"""
    is_limit_max(x::Integer, T::Type = typeof(x))

Check if `x` equals LIMIT_MAX for the given integer type `T`.
"""
is_limit_max(x::Integer, ::Type{T} = typeof(x)) where {T<:Integer} =
    x == convert(T, LIMIT_MAX)

# Show methods for nice printing
Base.show(io::IO, ::UndefinedType) = print(io, "UNDEFINED")
Base.show(io::IO, ::PositiveInfinityType) = print(io, "POSITIVE_INFINITY")
Base.show(io::IO, ::NegativeInfinityType) = print(io, "NEGATIVE_INFINITY")
Base.show(io::IO, ::LimitMaxType) = print(io, "LIMIT_MAX")

# tril enum re-exports from LibSemigroups

"""
    tril

Ternary logic type representing true, false, or unknown values.
Use `tril_TRUE`, `tril_FALSE`, and `tril_unknown` for the possible values.
"""
const tril = LibSemigroups.tril

"""
    tril_FALSE

The false value of the ternary logic type [`tril`](@ref).
"""
const tril_FALSE = LibSemigroups.tril_FALSE

"""
    tril_TRUE

The true value of the ternary logic type [`tril`](@ref).
"""
const tril_TRUE = LibSemigroups.tril_TRUE

"""
    tril_unknown

The unknown value of the ternary logic type [`tril`](@ref).
"""
const tril_unknown = LibSemigroups.tril_unknown

"""
    tril_to_bool(t::tril) -> Union{Bool, Nothing}

Convert a `tril` value to a Julia `Bool` or `nothing`.
Returns `true` for `tril_TRUE`, `false` for `tril_FALSE`,
and `nothing` for `tril_unknown`.
"""
tril_to_bool(t) = LibSemigroups.tril_to_bool(t)
