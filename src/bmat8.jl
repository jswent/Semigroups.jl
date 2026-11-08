# Copyright (c) 2026, James W. Swent, J. D. Mitchell
#
# Distributed under the terms of the GPL license version 3.
#
# The full license is in the file LICENSE, distributed with this software.

"""
bmat8.jl - High-level Julia API for BMat8

This file provides user-facing BMat8 functionality with idiomatic Julia
interfaces: 1-based indexing, and standard Julia operators.
"""

########################################################################
# BMat8
########################################################################

"""
Fast boolean matrices of dimension up to 8 x 8.

This class represents 8 x 8 matrices over the boolean semiring. The functions
for these small matrices over the boolean semiring are more optimised than the
generic functions for boolean matrices. Note that all [`BMat8`](@ref) are
represented internally as an 8 x 8 matrix; any entries not defined by the user
are taken to be `0`. This does not affect the results of any calculations.

# Example
```jldoctest
julia> using Semigroups

julia> x = BMat8([[0, 1], [1, 0]])
BMat8([[0, 1],
       [1, 0]])

julia> x[1, 1] = 1
1

julia> x
BMat8([[1, 1],
       [1, 0]])

julia> x[1, 2]
true

julia> x[2, 2]
false

julia> x * x
BMat8([[1, 1],
       [1, 1]])

julia> x < x * x
true

julia> x *= x
BMat8([[1, 1],
       [1, 1]])

julia> x
BMat8([[1, 1],
       [1, 1]])

julia> to_int(x)
0xc0c0000000000000

julia> string(to_int(x), base=2)
"1100000011000000000000000000000000000000000000000000000000000000"

julia> x == BMat8([[1, 1, 0], [1, 1, 0], [0, 0, 0]]) # All BMat8's are really 8x8!
true

julia> y = BMat8([[1, 0, 1], [0, 1, 0], [0, 0, 0]])
BMat8([[1, 0, 1],
       [0, 1, 0],
       [0, 0, 0]])

julia> y[1]  # The first row
8-element Vector{Bool}:
 1
 0
 1
 0
 0
 0
 0
 0

julia> x + y
BMat8([[1, 1, 1],
       [1, 1, 0],
       [0, 0, 0]])

julia> x += y
BMat8([[1, 1, 1],
       [1, 1, 0],
       [0, 0, 0]])

julia> 1 * x == x
true

julia> x * 0
BMat8(0)

julia> Dict(BMat8(0) => 1)
Dict{Semigroups.LibSemigroups.BMat8Allocated, Int64} with 1 entry:
  BMat8(0) => 1
```

[`BMat8`](@ref) objects can be used with the following algorithms in
Semigroups.jl

* [`Action`](@ref)
* [`FroidurePin`](@ref)
* [`Konieczny`](@ref)
"""
const BMat8 = LibSemigroups.BMat8

########################################################################
# Base overloads
########################################################################


function Base.show(io::IO, x::BMat8)
    print(io, @wrap_libsemigroups_call LibSemigroups.to_human_readable_repr(x))
end

function Base.getindex(x::BMat8, r::Int64, c::Int64)::Bool
    return @wrap_libsemigroups_call LibSemigroups.at(x, UInt(r - 1), UInt(c - 1))
end

function Base.getindex(x::BMat8, r::Int64)::Vector{Bool}
    return @wrap_libsemigroups_call LibSemigroups.at(x, UInt(r - 1))
end

function Base.setindex!(x::BMat8, val::T, r::Int64, c::Int64) where {T<:Union{Bool,Int64}}
    @wrap_libsemigroups_call LibSemigroups.bmat8_setitem(
        x,
        UInt(r - 1),
        UInt(c - 1),
        Bool(val),
    )
end

function Base.setindex!(x::BMat8, row::Vector{UInt8}, r::Int64)
    @wrap_libsemigroups_call LibSemigroups.bmat8_setrow(x, UInt(r - 1), row)
end

function Base.setindex!(x::BMat8, row::Vector{T}, r::Int64) where {T<:Union{Bool,Int64}}
    @wrap_libsemigroups_call setindex!(x, Vector{UInt8}(row), r)
end

Base.:(==)(x::BMat8, y::BMat8)::Bool = LibSemigroups.is_equal(x, y)
Base.isequal(x::BMat8, y::BMat8)::Bool = LibSemigroups.is_equal(x, y)
Base.:(<)(x::BMat8, y::BMat8)::Bool = LibSemigroups.is_less(x, y)
Base.isless(x::BMat8, y::BMat8)::Bool = LibSemigroups.is_less(x, y)
Base.:(<=)(x::BMat8, y::BMat8)::Bool = LibSemigroups.is_less_equal(x, y)
Base.:(>)(x::BMat8, y::BMat8)::Bool = LibSemigroups.is_greater(x, y)
Base.:(>=)(x::BMat8, y::BMat8)::Bool = LibSemigroups.is_greater_equal(x, y)
Base.:(*)(x::BMat8, y::BMat8)::BMat8 = LibSemigroups.multiply_bmat8_bmat8(x, y)
Base.:(*)(x::BMat8, y::T) where {T<:Union{Bool,Int64}} =
    LibSemigroups.multiply_bmat8_bool(x, Bool(y))
Base.:(*)(x::T, y::BMat8) where {T<:Union{Bool,Int64}} =
    LibSemigroups.multiply_bool_bmat8(Bool(x), y)
Base.:(+)(x::BMat8, y::BMat8)::BMat8 = LibSemigroups.add(x, y)

Base.copy(x::BMat8)::BMat8 = LibSemigroups.copy(x)
Base.hash(x::BMat8, h::UInt)::UInt64 = hash(LibSemigroups.hash_value(x), h)
Base.transpose(x::BMat8)::BMat8 = LibSemigroups.bmat8_transpose(x)

########################################################################
# Semigroups.jl functions
########################################################################

# TODO document the 0-arg constructor

"""
    BMat8(rows::Vector{Vector{T}})::BMat8 where {T<:Union{Bool,Int64}} -> BMat8

Construct from Vector of rows.

This constructor initializes a matrix where the rows of the matrix are the
lists in *rows*.

# Arguments
- `rows::Vector{Vector{T}} where {T<:Union{Bool,Int64}}`: the rows of the matrix.

# Throws
- `MethodError`: if `rows` has `0` rows.
- `LibsemigroupsError`: if `rows` has more than `8` rows.
- `LibsemigroupsError`: if the items in `rows` are not all of the same length.

# Complexity
- Constant.
"""
function BMat8(rows::Vector{Vector{T}})::BMat8 where {T<:Union{Bool,Int64}}
    result = BMat8(0)
    n = length(rows[1])
    for (i, row) in enumerate(rows)
        if length(row) != n
            throw(
                LibsemigroupsError(
                    "the entries of the argument (rows) must all be the same length $n, found length $(length(row)) for row with index $i",
                ),
            )
        end
        result[i] = row
    end
    return result
end

########################################################################
# Mem fns
########################################################################

"""
    degree(x::BMat8) -> Int64

Returns the degree of a [`BMat8`](@ref).

This function returns the degree of `x` which always returns `8`.

# Arguments
- `x::BMat8`: the matrix. 
"""
degree(x::BMat8)::Int64 = LibSemigroups.degree(x)

"""
    swap!(x::BMat8, y::BMat8) -> nothing

Swaps two [`BMat8`](@ref) objects.

This function swaps the values of `x` and `y`.

# Arguments
- `x::BMat8`: the first matrix to swap.
- `y::BMat8`: the second matrix to swap.

# Complexity
- Constant.

# Example
```jldoctest
julia> using Semigroups

julia> x = BMat8([[0, 1], [1, 0]])
BMat8([[0, 1],
       [1, 0]])

julia> y = BMat8([[1, 1], [0, 0]])
BMat8([[1, 1],
       [0, 0]])

julia> swap!(x, y)

julia> x
BMat8([[1, 1],
       [0, 0]])

julia> y
BMat8([[0, 1],
       [1, 0]])
```
"""
swap!(x::BMat8, y::BMat8)::Nothing = LibSemigroups.swap(x, y)

"""
    to_int(x::BMat8) -> UInt64

Returns the integer representation of a [`BMat8`](@ref).

This function returns a non-negative integer obtained by interpreting an 8 x 8
[`BMat8`](@ref) as a sequence of `64` bits (reading rows left to right, from top
to bottom) and then realising this sequence as an integer.

# Arguments
- `x::BMat8`: the matrix. 

# Complexity
- Constant.

# Example
```jldoctest
julia> using Semigroups

julia> x = BMat8([[0, 1], [1, 0]])
BMat8([[0, 1],
       [1, 0]])

julia> to_int(x)
0x4080000000000000

julia> string(to_int(x), base=2)
"100000010000000000000000000000000000000000000000000000000000000"
```
"""
to_int(x::BMat8)::UInt64 = LibSemigroups.to_int(x)

########################################################################
# Helpers
########################################################################

"""
     col_space_basis(x::BMat8) -> BMat8

Find a basis for the column space of a [`BMat8`](@ref).

This function returns a [`BMat8`](@ref) whose non-zero columns form a basis for
the column space of `x`.

# Arguments
- `x::BMat8`: the matrix.

# Complexity
-  Constant.

# Example

```jldoctest
julia> using Semigroups

julia> x = BMat8([[1, 0, 1], [0, 1, 0], [0, 0, 0]])
BMat8([[1, 0, 1],
       [0, 1, 0],
       [0, 0, 0]])

julia> col_space_basis(x)
BMat8([[1, 0],
       [0, 1]])
```
"""
col_space_basis(x::BMat8)::BMat8 = LibSemigroups.bmat8_col_space_basis(x)

"""
     col_space_size(x::BMat8) -> Int64

Returns the size of the column space of a [`BMat8`](@ref).

# Arguments
- `x::BMat8`: the matrix.

# Complexity
- ``O(n)`` where ``n`` is the return value of this function.

# See Also
- [`row_space_size`](@ref).

# Example

```jldoctest
julia> using Semigroups

julia> x = BMat8([[0, 1], [1, 0]])
BMat8([[0, 1],
       [1, 0]])

julia> col_space_size(x)
4
```
"""
col_space_size(x::BMat8)::Int64 = LibSemigroups.bmat8_col_space_size(x)

"""
    is_regular_element(x::BMat8) -> Bool

Check whether `x` is a regular element of the full boolean matrix monoid of
appropriate dimension.

This function returns `true` if there exists a boolean matrix `y` such that 
`x * y * x = x` where `x`, and `false` otherwise.

# Arguments
- `x::BMat8`: the matrix.

# Complexity
- Constant.

# Example

```jldoctest
julia> using Semigroups

julia> x = BMat8([[0, 1], [1, 0]])
BMat8([[0, 1],
       [1, 0]])

julia> is_regular_element(x)
true

julia> sum(1 for x in 0:100000 if is_regular_element(BMat8(x)))
97997
```
"""
is_regular_element(x::BMat8)::Bool = LibSemigroups.bmat8_is_regular_element(x)

"""
    minimum_dim(x::BMat8) -> Int64:

Returns the minimum dimension of a [`BMat8`](@ref).

This function returns the maximal `n` such that row `n` or column `n` in the
boolean matrix `x` contains at least one occurrence of `1`. Equivalent to the
maximum of [`number_of_rows`](@ref) and [`number_of_cols`](@ref).

# Arguments
- `x::BMat8`: the matrix.

# Complexity
- Constant.

# Example

```jldoctest
julia> using Semigroups   

julia> x = BMat8([[0, 1], [1, 0]])
BMat8([[0, 1],
       [1, 0]])

julia> minimum_dim(x)
2
```
"""
minimum_dim(x::BMat8)::Int64 = LibSemigroups.bmat8_minimum_dim(x)

"""
    number_of_cols(x::BMat8) -> Int64

Returns the number of non-zero columns in a [`BMat8`](@ref).

[`BMat8`](@ref) objects do not know their "dimension" - in effect they are all of
dimension `8`. However, this function can be used to obtain the number of
non-zero columns of a [`BMat8`](@ref).

# Arguments
- `x::BMat8`: the matrix.

# Complexity
-  Constant.

# See also

[`number_of_rows(::BMat8)`](@ref) and [`minimum_dim(::BMat8)`](@ref).

# Example
```jldoctest
julia> using Semigroups   

julia> x = BMat8([[1, 0, 1], [0, 1, 0], [0, 0, 0]])
BMat8([[1, 0, 1],
       [0, 1, 0],
       [0, 0, 0]])

julia> number_of_cols(x)
3
```
"""
number_of_cols(x::BMat8)::Int64 = LibSemigroups.bmat8_number_of_cols(x)

"""
    number_of_rows(x::BMat8) -> Int64

Returns the number of non-zero rows in a [`BMat8`](@ref).

[`BMat8`](@ref) objects do not know their "dimension" - in effect they are all of
dimension `8`. However, this function can be used to obtain the number of
non-zero rows of a [`BMat8`](@ref).

# Arguments
- `x::BMat8`: the matrix.

# Complexity
-  Constant.

# See also

[`number_of_cols(::BMat8)`](@ref) and [`minimum_dim(::BMat8)`](@ref).

# Example

```jldoctest
julia> using Semigroups   

julia> x = BMat8([[1, 0, 1], [0, 1, 0], [0, 0, 0]])
BMat8([[1, 0, 1],
       [0, 1, 0],
       [0, 0, 0]])

julia> number_of_rows(x)
2
```
"""
number_of_rows(x::BMat8)::Int64 = LibSemigroups.bmat8_number_of_rows(x)

"""
    one(::Type{BMat8}, dim::Int64) -> BMat8

Returns the identity [`BMat8`](@ref) of a given dimension.

This function returns the [`BMat8`](@ref) with the first `dim` entries in the
main diagonal equal to `1` and every other value equal to `0`.

# Arguments
- `dim::Int64`: the dimension. 

# Throws
- `LibsemigroupsError`: if `dim` is not in the interval ``[0, 8]``.

# Complexity
-  Constant.

# Example
```jldoctest
julia> using Semigroups

julia> one(BMat8, 4)
BMat8([[1, 0, 0, 0],
       [0, 1, 0, 0],
       [0, 0, 1, 0],
       [0, 0, 0, 1]])
```
"""
function Base.one(::Type{BMat8}, n::Int64)::BMat8
    0 <= n <= 8 || throw(LibsemigroupsError("identity matrix dimension must be in [0, 8]"))
    return @wrap_libsemigroups_call LibSemigroups.bmat8_one(n)
end

"""
    one(sample::BMat8, dim::Int64) -> BMat8

Returns the identity [`BMat8`](@ref) of a given dimension.

This function returns the [`BMat8`](@ref) with the first `dim` entries in the
main diagonal equal to `1` and every other value equal to `0`.

# Arguments
- `sample::BMat8`: a matrix.
- `dim::Int64`: the dimension. 

# Throws
- `LibsemigroupsError`: if `dim` is not in the interval ``[0, 8]``.

# Complexity
-  Constant.

# Example
```jldoctest
julia> using Semigroups

julia> x = BMat8([[1, 0, 1], [0, 1, 0], [0, 0, 0]])
BMat8([[1, 0, 1],
       [0, 1, 0],
       [0, 0, 0]])

julia> one(x, 4)
BMat8([[1, 0, 0, 0],
       [0, 1, 0, 0],
       [0, 0, 1, 0],
       [0, 0, 0, 1]])
```
"""
Base.one(::BMat8, n::Int64)::BMat8 = Base.one(BMat8, n)

"""
    random(::Type{BMat8}, dim::Int64) -> BMat8

Construct a random [`BMat8`](@ref) of dimension at most `dim`.

This function returns a [`BMat8`](@ref) chosen at random, where only the top-left
`dim` by `dim` entries can be non-zero.

# Arguments
- `dim::Int64`: the dimension.

# Throws
- `LibsemigroupsError`: if `dim` is not in the interval ``[1, 8]``.
"""
random(::Type{BMat8}, n::Int64)::BMat8 =
    @wrap_libsemigroups_call LibSemigroups.bmat8_random(n)

"""
    random(sample::BMat8, dim::Int64) -> BMat8

Construct a random [`BMat8`](@ref) of dimension at most `dim`.

This function returns a [`BMat8`](@ref) chosen at random, where only the top-left
`dim` by `dim` entries can be non-zero.

# Arguments
- `sample::BMat8`: a matrix.
- `dim::Int64`: the dimension.

# Throws
- `LibsemigroupsError`: if `dim` is not in the interval ``[1, 8]``.
"""
random(::BMat8, n::Int64)::BMat8 = @wrap_libsemigroups_call LibSemigroups.bmat8_random(n)

"""
     row_space_basis(x::BMat8) -> BMat8

Find a basis for the row space of a [`BMat8`](@ref).

This function returns a [`BMat8`](@ref) whose non-zero rows form a basis for
the row space of `x`.

# Arguments
- `x::BMat8`: the matrix.

# Complexity
-  Constant.

# Example

```jldoctest
julia> using Semigroups

julia> x = BMat8([[1, 0, 1], [0, 1, 0], [0, 0, 0]])
BMat8([[1, 0, 1],
       [0, 1, 0],
       [0, 0, 0]])

julia> row_space_basis(x)
BMat8([[1, 0, 1],
       [0, 1, 0],
       [0, 0, 0]])
```
"""
row_space_basis(x::BMat8)::BMat8 = LibSemigroups.bmat8_row_space_basis(x)

"""
     row_space_size(x::BMat8) -> Int64

Returns the size of the row space of a [`BMat8`](@ref).

# Arguments
- `x::BMat8`: the matrix.

# Complexity
- ``O(n)`` where ``n`` is the return value of this function.

# See Also
- [`col_space_size`](@ref).

# Example

```jldoctest
julia> using Semigroups

julia> x = BMat8([[0, 1], [1, 0]])
BMat8([[0, 1],
       [1, 0]])

julia> row_space_size(x)
4
```
"""
row_space_size(x::BMat8)::Int64 = LibSemigroups.bmat8_row_space_size(x)

"""
rows(x::BMat8) -> Vector{Vector{Bool}}

Returns the rows of a [`BMat8`](@ref).

This function returns the rows of `x`. The returned `Vector` always has length
`8`, even if `x` was constructed with fewer rows.

# Arguments
- `x::BMat8`: the matrix.

# Complexity
-  Constant.

# Example

```jldoctest
julia> using Semigroups

julia> x = BMat8([[0, 1], [1, 0]])
BMat8([[0, 1],
       [1, 0]])

julia> rows(x)
8-element Vector{Vector{Bool}}:
 [0, 1, 0, 0, 0, 0, 0, 0]
 [1, 0, 0, 0, 0, 0, 0, 0]
 [0, 0, 0, 0, 0, 0, 0, 0]
 [0, 0, 0, 0, 0, 0, 0, 0]
 [0, 0, 0, 0, 0, 0, 0, 0]
 [0, 0, 0, 0, 0, 0, 0, 0]
 [0, 0, 0, 0, 0, 0, 0, 0]
 [0, 0, 0, 0, 0, 0, 0, 0]
```
"""
rows(x::BMat8)::Vector{Vector{Bool}} = LibSemigroups.bmat8_rows(x)
