# Copyright (c) 2026, James W. Swent
#
# Distributed under the terms of the GPL license version 3.
#
# The full license is in the file LICENSE, distributed with this software.

"""
test_constants.jl - Tests for libsemigroups constants
"""

@testset "Constants" begin
    # Test UNDEFINED conversions
    @test convert(UInt8, UNDEFINED) == typemax(UInt8)
    @test convert(UInt16, UNDEFINED) == typemax(UInt16)
    @test convert(UInt32, UNDEFINED) == typemax(UInt32)
    @test convert(UInt64, UNDEFINED) == typemax(UInt64)

    # Test POSITIVE_INFINITY conversions
    @test convert(UInt8, POSITIVE_INFINITY) == typemax(UInt8) - 1
    @test convert(UInt16, POSITIVE_INFINITY) == typemax(UInt16) - 1
    @test convert(UInt32, POSITIVE_INFINITY) == typemax(UInt32) - 1
    @test convert(UInt64, POSITIVE_INFINITY) == typemax(UInt64) - 1

    # Test LIMIT_MAX conversions
    @test convert(UInt8, LIMIT_MAX) == typemax(UInt8) - 2
    @test convert(UInt16, LIMIT_MAX) == typemax(UInt16) - 2
    @test convert(UInt32, LIMIT_MAX) == typemax(UInt32) - 2
    @test convert(UInt64, LIMIT_MAX) == typemax(UInt64) - 2

    # Test NEGATIVE_INFINITY conversions
    @test convert(Int8, NEGATIVE_INFINITY) == typemin(Int8)
    @test convert(Int16, NEGATIVE_INFINITY) == typemin(Int16)
    @test convert(Int32, NEGATIVE_INFINITY) == typemin(Int32)
    @test convert(Int64, NEGATIVE_INFINITY) == typemin(Int64)

    # Test equality comparisons
    @test UNDEFINED == UNDEFINED
    @test POSITIVE_INFINITY == POSITIVE_INFINITY
    @test NEGATIVE_INFINITY == NEGATIVE_INFINITY
    @test LIMIT_MAX == LIMIT_MAX

    @test !(UNDEFINED == POSITIVE_INFINITY)
    @test !(UNDEFINED == NEGATIVE_INFINITY)
    @test !(POSITIVE_INFINITY == NEGATIVE_INFINITY)

    # Test ordering comparisons
    @test NEGATIVE_INFINITY < POSITIVE_INFINITY
    @test !(POSITIVE_INFINITY < NEGATIVE_INFINITY)
    @test 0 < POSITIVE_INFINITY
    @test !(POSITIVE_INFINITY < 0)
    @test NEGATIVE_INFINITY < 0
    @test !(0 < NEGATIVE_INFINITY)

    # Test is_* helper functions
    @test is_undefined(typemax(UInt64))
    @test is_positive_infinity(typemax(UInt64) - 1)
    @test is_limit_max(typemax(UInt64) - 2)
    @test is_negative_infinity(typemin(Int64))
end

@testset "tril enum" begin
    @test tril_FALSE != tril_TRUE
    @test tril_FALSE != tril_unknown
    @test tril_TRUE != tril_unknown

    @test tril_to_bool(tril_TRUE) === true
    @test tril_to_bool(tril_FALSE) === false
    @test tril_to_bool(tril_unknown) === nothing
end
