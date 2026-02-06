# Copyright (c) 2026, James W. Swent
#
# Distributed under the terms of the GPL license version 3.
#
# The full license is in the file LICENSE, distributed with this software.

"""
test_errors.jl - Tests for error handling utilities
"""

@testset "Error Handling" begin
    @testset "LibsemigroupsError type" begin
        err = Semigroups.LibsemigroupsError("test message")
        @test err isa Exception
        @test err.msg == "test message"

        # showerror formatting
        buf = IOBuffer()
        Base.showerror(buf, err)
        @test String(take!(buf)) == "LibsemigroupsError: test message"
    end

    @testset "extract_message" begin
        # Strips C++ prefix
        @test Semigroups.Errors.extract_message(
            "/path/file.cpp:42:func_name: actual message",
        ) == "actual message"

        # Returns original if no prefix
        @test Semigroups.Errors.extract_message("no prefix message") == "no prefix message"
    end

    @testset "@wrap_libsemigroups_call" begin
        # Successful call passes through
        result = Semigroups.Errors.@wrap_libsemigroups_call begin
            42
        end
        @test result == 42

        # Exception is caught and rethrown as LibsemigroupsError
        @test_throws Semigroups.LibsemigroupsError begin
            Semigroups.Errors.@wrap_libsemigroups_call begin
                error("some C++ error")
            end
        end

        # Prefix is stripped from the error message
        try
            Semigroups.Errors.@wrap_libsemigroups_call begin
                error("/path/file.cpp:10:some_func: value out of bounds")
            end
            @test false  # should not reach here
        catch ex
            @test ex isa Semigroups.LibsemigroupsError
            @test ex.msg == "value out of bounds"
        end
    end

    @testset "Julia-side transformation errors" begin
        # Zero degree Transf
        @test_throws ErrorException Transf(Int[])

        # Zero degree PPerm (from images)
        @test_throws ErrorException PPerm([])

        # Zero degree Perm
        @test_throws ErrorException Perm(Int[])

        # Invalid permutation (not a bijection)
        @test_throws ErrorException Perm([1, 1, 2])

        # DimensionMismatch for PPerm with mismatched domain/image
        @test_throws ErrorException PPerm([1, 2], [3], 4)

        # Degree too large
        @test_throws ErrorException Semigroups._scalar_type_from_degree(2^33)
    end

    @testset "Successful operations (no error overhead)" begin
        # Valid Transf
        t = Transf([2, 1, 3])
        @test degree(t) == 3
        @test t[1] == 2

        # Valid PPerm
        p = PPerm([2, UNDEFINED, 1])
        @test degree(p) == 3
        @test p[1] == 2
        @test p[2] === UNDEFINED

        # Valid PPerm from domain/image
        p2 = PPerm([1, 3], [2, 1], 3)
        @test degree(p2) == 3

        # Valid Perm
        perm = Perm([2, 3, 1])
        @test degree(perm) == 3
        @test perm[1] == 2
    end
end
