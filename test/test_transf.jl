# Copyright (c) 2026, James W. Swent
#
# Distributed under the terms of the GPL license version 3.
#
# The full license is in the file LICENSE, distributed with this software.

"""
test_transf.jl - Tests for transformation types (Transf, PPerm, Perm)

Ported from libsemigroups_pybind11/tests/test_transf.py
"""

# ============================================================================
# Helper functions for testing
# ============================================================================

function check_one_ops(T, x)
    # one(x), operator==, and operator!=
    id = one(T, degree(x))
    @test one(x) == id
    @test one(x) != x
    @test x > one(x)
    @test one(x) < x
    @test one(x) <= x
    @test x <= x
    @test one(x) <= one(x)
    @test x >= one(x)
end

function check_product_inplace(x)
    # Note: Julia doesn't support product_inplace at high level yet,
    # this tests the multiplication operator
    y = one(x)
    z = one(x)
    # z = product_inplace(z, x, y) would be z = x * y
    @test x * y == x
    @test y * x == x
    @test x * x == x * x
end

function check_transf_basic(T)
    # Test basic construction and validation
    # Python: T([1, 1, 2, 16] + list(range(4, 16))) raises RuntimeError (16 is out of range for length 16 in 0-based)
    # Julia: Need value out of range for 1-based indexing
    # This should error because 5 is out of range for degree 4
    # C++ make<> validation throws an exception (any exception type)
    @test_throws Exception T([1, 2, 3, 5])

    # Test __getitem__ (Julia: getindex with 1-based indexing)
    # Python: x = T([1, 1, 2, 3] + list(range(4, 16)))  (0-based)
    # Julia: x = T([2, 2, 3, 4, 5, ..., 17])  (1-based, maps i->i+1)
    x = T([2, 2, 3, 4, 5:17...])
    @test x[1] == 2
    @test x[2] == 2
    @test x[3] == 3
    @test x[4] == 4

    # Check one operations
    check_one_ops(T, x)

    # Test rank
    @test rank(x) == 16  # 16 distinct values: 2,3,4,...,17
    @test rank(one(x)) == 17
    @test rank(T([1 for _ = 1:17])) == 1

    # Test degree
    @test degree(x) == 17
    @test degree(one(x)) == 17
    @test degree(T([1 for _ = 1:17])) == 17

    # Product operations
    check_product_inplace(x)

    # Test images
    @test images(x) == [2, 2, 3, 4, 5:17...]

    # More complex transformation
    # Python: x = T([15, 5, 2, 10, 17, 8, 13, 15, 1, 9, 4, 0, 15, 5, 14, 11, 15, 4, 7, 3])
    # Julia: add 1 to each value for 1-based
    x = T([16, 6, 3, 11, 18, 9, 14, 16, 2, 10, 5, 1, 16, 6, 15, 12, 16, 5, 8, 4])
    @test degree(x) == 20
    @test rank(x) == 15
    @test x[6] == 9  # Python x[5] == 8 (0-based)
    # Test triple product
    x3 = x * x * x
    expected = T([1, 2, 3, 18, 18, 6, 9, 1, 9, 10, 5, 12, 1, 2, 15, 16, 1, 5, 12, 5])
    @test x3 == expected
end

function check_pperm_basic(T)
    # Test construction from domain, image, degree
    # Python: x = T([1, 2, 3], [4, 7, 6], 16) (0-based)
    # Julia: x = T([2, 3, 4], [5, 8, 7], 17) (1-based)
    x = T([2, 3, 4], [5, 8, 7], 17)
    @test x[1] === UNDEFINED
    @test x[2] == 5
    @test x[3] == 8
    @test x[4] == 7
    @test x[5] === UNDEFINED

    # Check one operations
    check_one_ops(T, x)

    # Test specific PPerm operations
    @test x * right_one(x) == x
    @test left_one(x) * x == x
    @test x * inv(x) == left_one(x)
    @test inv(x) * x == right_one(x)

    # Test rank
    @test rank(x) == 3
    @test rank(one(x)) == 17

    # Test degree
    @test degree(x) == 17
    @test degree(one(x)) == 17

    # Product operations
    check_product_inplace(x)

    # Test images - should have UNDEFINED for undefined points
    imgs = [x[i] for i = 1:degree(x)]
    @test imgs[1] === UNDEFINED
    @test imgs[2] == 5
    @test imgs[3] == 8
    @test imgs[4] == 7
    @test all(imgs[i] === UNDEFINED for i = 5:17)
end

function check_perm_basic(T)
    # Python: x = T([1, 2, 3, 0, 6, 5, 4] + list(range(7, 16)))
    # Julia: x = T([2, 3, 4, 1, 7, 6, 5, 8, 9, ..., 17])
    x = T([2, 3, 4, 1, 7, 6, 5, 8:17...])
    @test x[1] == 2
    @test x[2] == 3
    @test x[3] == 4
    @test x[4] == 1
    @test x[5] == 7

    # Check one operations
    check_one_ops(T, x)

    # Test inverse
    @test inv(x) * x == one(x)
    @test x * inv(x) == one(x)

    # Test rank (always equals degree for permutations)
    @test rank(x) == 17
    @test rank(one(x)) == 17

    # Test degree
    @test degree(x) == 17
    @test degree(one(x)) == 17

    # Product operations
    check_product_inplace(x)

    # Test images
    @test images(x) == [2, 3, 4, 1, 7, 6, 5, 8:17...]
end

# ============================================================================
# Main test sets
# ============================================================================

@testset "Transformations" begin
    @testset "Transf - Basic operations" begin
        check_transf_basic(Transf)
    end

    @testset "PPerm - Basic operations" begin
        check_pperm_basic(PPerm)
    end

    @testset "Perm - Basic operations" begin
        check_perm_basic(Perm)
    end

    @testset "Transf - Construction and validation" begin
        # Valid construction
        t = Transf([2, 1, 2, 3])
        @test degree(t) == 4
        @test rank(t) == 3

        # Test that empty degree fails
        @test_throws Exception Transf(Int[])

        # Test 1-based indexing access
        @test t[1] == 2
        @test t[2] == 1
        @test t[3] == 2
        @test t[4] == 3

        # Test bounds checking
        @test_throws BoundsError t[0]
        @test_throws BoundsError t[5]
    end

    @testset "PPerm - Construction and validation" begin
        # Construction from images
        p = PPerm([2, UNDEFINED, 1, 4])
        @test degree(p) == 4
        @test p[1] == 2
        @test p[2] === UNDEFINED
        @test p[3] == 1
        @test p[4] == 4

        # Construction from domain, image, degree
        p2 = PPerm([1, 3], [2, 4], 5)
        @test degree(p2) == 5
        @test p2[1] == 2
        @test p2[2] === UNDEFINED
        @test p2[3] == 4
        @test p2[4] === UNDEFINED
        @test p2[5] === UNDEFINED

        # Test domain_set and image_set
        @test domain_set(p2) == [1, 3]
        @test image_set(p2) == [2, 4]
    end

    @testset "Perm - Construction and validation" begin
        # Valid permutation
        p = Perm([2, 3, 1])
        @test degree(p) == 3
        @test rank(p) == 3
        @test p[1] == 2
        @test p[2] == 3
        @test p[3] == 1

        # Invalid permutation (not a bijection)
        @test_throws ErrorException Perm([1, 1, 2])
        @test_throws ErrorException Perm([1, 2, 4])  # Missing 3
    end

    @testset "Operators and comparisons" begin
        # Test with different degrees
        t1 = Transf([1])
        t2 = Transf([1, 2])
        @test t1 != t2
        @test t1 < t2

        # Test multiplication
        t3 = Transf([2, 1])
        t4 = Transf([1, 2])
        @test t3 * t4 == t3
        @test t4 * t3 == t3

        # Test equality and ordering
        t5 = Transf([2, 1])
        @test t3 == t5
        @test !(t3 < t5)
        @test t3 <= t5
        @test t3 >= t5
    end

    @testset "Copy functionality" begin
        x = Transf([1, 2])
        y = copy(x)
        @test x !== y  # Different objects
        @test x == y   # But equal values
    end

    @testset "Images and iteration" begin
        x = Transf(1:18)
        @test images(x) == collect(1:18)

        # Test iteration
        count = 0
        for img in x
            count += 1
        end
        @test count == 18
    end

    @testset "Hash and Set membership" begin
        # Test that transformations can be used in Sets and Dicts
        t1 = Transf([2, 1])
        t2 = Transf([2, 1])
        t3 = Transf([1, 2])

        s = Set([t1, t2, t3])
        @test length(s) == 2  # t1 and t2 are equal

        d = Dict(t1 => 1, t3 => 2)
        @test d[t2] == 1  # t2 equals t1
    end

    @testset "Display and string representation" begin
        # Test show methods
        t = Transf([1])
        io = IOBuffer()
        show(io, t)
        str = String(take!(io))
        @test occursin("Transf", str)

        # Test longer transformations show abbreviated form
        t_long = Transf(1:20)
        io = IOBuffer()
        show(io, t_long)
        str = String(take!(io))
        @test occursin("degree", str) && occursin("rank", str)
    end

    @testset "image and domain helper functions" begin
        # Transf
        x = Transf([1, 1, 2])
        @test sort(image_set(x)) == [1, 2]

        # PPerm
        x = PPerm([1, 2], [3, 2], 4)
        @test domain_set(x) == [1, 2]
        @test image_set(x) == [2, 3]

        # Perm
        x = Perm([1, 2])
        @test sort(image_set(x)) == [1, 2]
    end

    @testset "Inverse operations" begin
        # PPerm inverse
        p = PPerm([1, 3], [2, 4], 5)
        p_inv = inv(p)
        @test p * p_inv == left_one(p)
        @test p_inv * p == right_one(p)

        # Perm inverse
        perm = Perm([2, 3, 1])
        perm_inv = inv(perm)
        @test perm * perm_inv == one(perm)
        @test perm_inv * perm == one(perm)
    end

    @testset "Corner cases" begin
        # Edge case: PPerm with maximum value for UInt8
        p = PPerm([256], [256], 256)
        @test rank(p) == 1

        # Empty PPerm
        p_empty = PPerm(Int[], Int[], 1)
        @test degree(p_empty) == 1
        @test rank(p_empty) == 0

        # Product of empty PPerms
        p1 = PPerm(Int[], Int[], 10)
        p2 = PPerm(Int[], Int[], 10)
        @test p1 * p2 == p1
    end

    # ========================================================================
    # Parametric type tests
    # ========================================================================

    function check_parametric_type(T)
        # Auto-selection: small degree → UInt8
        x8 = T(collect(1:10))
        @test x8 isa T{UInt8}
        @test degree(x8) == 10

        # Auto-selection: large degree → UInt16
        x16 = T(collect(1:300))
        @test x16 isa T{UInt16}
        @test degree(x16) == 300

        # Boundary: 255 → UInt8, 256 → UInt16
        @test T(collect(1:255)) isa T{UInt8}
        @test T(collect(1:256)) isa T{UInt16}

        # Explicit scalar type constructor
        x_explicit = T([1, 2, 3], UInt16)
        @test x_explicit isa T{UInt16}
        @test collect(x_explicit) == collect(T([1, 2, 3]))

        @test T([1, 2], UInt32) isa T{UInt32}

        # copy preserves type parameter
        @test copy(x8) isa T{UInt8}
        @test copy(x16) isa T{UInt16}
        @test copy(x8) == x8

        # one preserves type context
        @test one(x8) isa T{UInt8}
        @test one(x16) isa T{UInt16}

        # Same-type multiplication preserves type
        @test x8 * x8 isa T{UInt8}
        @test x16 * x16 isa T{UInt16}

        # Cross-type multiplication is not supported (must have same scalar type)
        @test_throws MethodError x8 * x16
        @test_throws MethodError x16 * x8
    end

    @testset "Parametric type - Transf" begin
        check_parametric_type(Transf)
    end

    @testset "Parametric type - PPerm" begin
        check_parametric_type(PPerm)

        # Domain/image/degree constructors: auto-selection
        @test PPerm([1, 3], [2, 4], 5) isa PPerm{UInt8}
        @test PPerm([1, 3], [2, 4], 300) isa PPerm{UInt16}
        @test PPerm(Int[], Int[], 255) isa PPerm{UInt8}
        @test PPerm(Int[], Int[], 256) isa PPerm{UInt16}

        # Domain/image/degree constructor: explicit type
        p_explicit = PPerm([1, 3], [2, 4], 5, UInt32)
        @test p_explicit isa PPerm{UInt32}
        @test collect(p_explicit) == collect(PPerm([1, 3], [2, 4], 5))

        # Images constructor with UNDEFINED and explicit type
        p_undef = PPerm([2, UNDEFINED, 1], UInt16)
        @test p_undef isa PPerm{UInt16}
        @test collect(p_undef) == collect(PPerm([2, UNDEFINED, 1]))

        # inv, left_one, right_one preserve type
        p = PPerm([2, UNDEFINED, 1])
        @test inv(p) isa PPerm{UInt8}
        @test left_one(p) isa PPerm{UInt8}
        @test right_one(p) isa PPerm{UInt8}
    end

    @testset "Parametric type - Perm" begin
        check_parametric_type(Perm)

        # inv preserves type
        @test inv(Perm([2, 3, 1])) isa Perm{UInt8}
        @test inv(Perm(circshift(collect(1:300), 1))) isa Perm{UInt16}
    end

    @testset "One and identity" begin
        # Test one() function and identity properties
        t = Transf([2, 1, 3])
        id = one(t)
        @test t * id == t
        @test id * t == t
        @test id == Transf([1, 2, 3])

        # Test static one
        id2 = one(Transf, 3)
        @test id == id2
    end

    function check_increase_degree_by!(T)
        x = T([1])
        @test degree(x) == 1
        increase_degree_by!(x, 2)
        @test degree(x) == 3
        increase_degree_by!(x, 15)
        @test degree(x) == 18
        increase_degree_by!(x, 15)
        @test degree(x) == 33
        increase_degree_by!(x, 255)
        @test degree(x) == 288
        increase_degree_by!(x, 2^16)
        @test degree(x) == 288 + 2^16
    end

    @testset "increase_degree_by! method" begin
        check_increase_degree_by!(Transf)
        check_increase_degree_by!(PPerm)
        check_increase_degree_by!(Perm)
    end


    @testset "swap! method" begin
        # Test swap for Transf
        x = Transf([1])
        y = Transf([1, 2])
        swap!(x, y)
        @test x == Transf([1, 2])
        @test y == Transf([1])

        # Test swap for PPerm
        p1 = PPerm([1], [2], 3)
        p2 = PPerm([1, 2], [3, 4], 5)
        swap!(p1, p2)
        @test p1 == PPerm([1, 2], [3, 4], 5)
        @test p2 == PPerm([1], [2], 3)

        # Test swap for Perm
        perm1 = Perm([1])
        perm2 = Perm([2, 1])
        swap!(perm1, perm2)
        @test perm1 == Perm([2, 1])
        @test perm2 == Perm([1])
    end

    @testset "Return policy tests" begin
        # Test that copy returns a new object
        for TestType in (Transf, PPerm, Perm)
            x = TestType([1])
            y = copy(x)
            @test x !== y  # Different objects
            @test x == y   # But equal values
        end

        # Test that images returns a new vector each time
        x = Transf([1, 2, 3])
        imgs1 = images(x)
        imgs2 = images(x)
        @test imgs1 !== imgs2  # Different vectors

        # Test that increase_degree_by! modifies in place and returns the same object
        x = Transf([1])
        result = increase_degree_by!(x, 5)
        @test result === x  # Same object
        @test degree(x) == 6
    end
end
