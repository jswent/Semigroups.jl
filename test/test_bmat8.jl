# Copyright (c) 2026, James Mitchell
#
# Distributed under the terms of the GPL license version 3.
#
# The full license is in the file LICENSE, distributed with this software.

"""
test_bmat8.jl - Tests for BMat8

More or less directly taken from the first version of the doc.
"""

using Test
using Semigroups

@testset verbose = true "BMat8" begin

    @testset "special members" begin
        x = BMat8([[0, 1], [1, 0]])
        @test x[1, 1] == false
        @test x[1, 2] == true
        @test x[2, 2] == false
        @test x * x == BMat8([[1, 0], [0, 1]])
        @test x < x * x
        x *= x
        @test x == BMat8([[1, 0], [0, 1]])

        @test to_int(x) == 0x8040000000000000
        @test string(to_int(x), base = 2) ==
              "1000000001000000000000000000000000000000000000000000000000000000"

        x = BMat8([[1, 1, 0], [1, 1, 0], [0, 0, 0]])
        y = BMat8([[1, 0, 1], [0, 1, 0], [0, 0, 0]])

        @test y[1] == [1, 0, 1, 0, 0, 0, 0, 0]
        @test x + y == BMat8([[1, 1, 1], [1, 1, 0], [0, 0, 0]])

        x += y
        @test x == BMat8([[1, 1, 1], [1, 1, 0], [0, 0, 0]])
        @test 1 * x == x
        @test x * 0 == BMat8(0)

        dict = Dict(BMat8(0) => 1)
        @test dict[BMat8(0)] == 1
    end

    @testset "swap!" begin

        x = BMat8([[0, 1], [1, 0]])
        y = BMat8([[1, 1], [0, 0]])

        swap!(x, y)
        @test x == BMat8([[1, 1], [0, 0]])
        @test y == BMat8([[0, 1], [1, 0]])
    end

    @testset "to_int" begin

        x = BMat8([[0, 1], [1, 0]])
        @test to_int(x) == 0x4080000000000000

        @test string(to_int(x), base = 2) ==
              "100000010000000000000000000000000000000000000000000000000000000"
    end

    @testset "col_space_basis" begin
        x = BMat8([[1, 0, 1], [0, 1, 0], [0, 0, 0]])
        @test col_space_basis(x) == BMat8([[1, 0], [0, 1]])
    end

    @testset "col_space_size" begin
        x = BMat8([[0, 1], [1, 0]])
        @test col_space_size(x) == 4
    end

    @testset "is_regular_element" begin
        x = BMat8([[0, 1], [1, 0]])

        @test is_regular_element(x) == true

        @test sum(1 for x = 0:100000 if is_regular_element(BMat8(x))) == 97997
    end

    @testset "minimum_dim" begin
        x = BMat8([[0, 1], [1, 0]])

        @test minimum_dim(x) == 2
    end

    @testset "number_of_cols/rows" begin

        x = BMat8([[1, 0, 1], [0, 1, 0], [0, 0, 0]])
        @test number_of_cols(x) == 3
        @test number_of_rows(x) == 2
    end

    @testset "one" begin

        @test one(BMat8, 4) ==
              BMat8([[1, 0, 0, 0], [0, 1, 0, 0], [0, 0, 1, 0], [0, 0, 0, 1]])
        x = BMat8([[1, 0, 1], [0, 1, 0], [0, 0, 0]])

        @test one(x, 4) == BMat8([[1, 0, 0, 0], [0, 1, 0, 0], [0, 0, 1, 0], [0, 0, 0, 1]])

        @test_throws LibsemigroupsError one(x, -1)
        @test_throws LibsemigroupsError one(BMat8, -1)
        @test_throws LibsemigroupsError one(x, 9)
        @test_throws LibsemigroupsError one(BMat8, 9)
    end

    @testset "random" begin

        # random(BMat8, 4) has nonzero entries only in the top-left 4×4 block,
        # so minimum_dim is at most 4 (can be less if random rows/cols are zero)
        @test minimum_dim(random(BMat8, 4)) <= 4

        x = BMat8([[1, 0, 1], [0, 1, 0], [0, 0, 0]])
        @test minimum_dim(random(x, 4)) <= 4

        @test_throws LibsemigroupsError random(x, 0)
        @test_throws LibsemigroupsError random(BMat8, 0)
        @test_throws LibsemigroupsError random(x, 9)
        @test_throws LibsemigroupsError random(BMat8, 9)

    end

    @testset "row_space_basis" begin
        x = BMat8([[1, 0, 1], [0, 1, 0], [0, 0, 0]])
        @test row_space_basis(x) == BMat8([[1, 0, 1], [0, 1, 0], [0, 0, 0]])
    end

    @testset "row_space_size" begin
        x = BMat8([[0, 1], [1, 0]])

        @test row_space_size(x) == 4
    end

    @testset "rows" begin
        x = BMat8([[0, 1], [1, 0]])

        @test rows(x) == [
            [0, 1, 0, 0, 0, 0, 0, 0],
            [1, 0, 0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0, 0, 0, 0],
        ]
    end
end
