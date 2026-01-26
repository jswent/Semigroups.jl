@testset "Error Handling" begin
    @testset "Error module internals" begin
        # Test extract_message
        @test Semigroups.Errors.extract_message(
            "/path/file.cpp:42:func_name: actual message",
        ) == "actual message"
        @test Semigroups.Errors.extract_message("no prefix message") == "no prefix message"

        # Test adjust_index
        @test Semigroups.Errors.adjust_index(0) == 1
        @test Semigroups.Errors.adjust_index(5) == 6

        # Test adjust_bounds
        @test Semigroups.Errors.adjust_bounds(0, 3) == (1, 4)
    end

    @testset "Bounds error translation" begin
        # Test translate_bounds_error
        msg = "image value out of bounds, expected value in [0, 3), found 5 in position 2"
        err = Semigroups.Errors.translate_bounds_error(msg)
        @test err isa DomainError
        @test err.val == 6  # 5 + 1 (1-based)
        @test occursin("position 3", err.msg)  # 2 + 1 (1-based)
        @test occursin("[1, 4)", err.msg)  # [0, 3) -> [1, 4)

        # Test non-matching message
        @test Semigroups.Errors.translate_bounds_error("unrelated message") === nothing
    end

    @testset "Duplicate error translation" begin
        msg = "duplicate image value, found 2 in position 3, first occurrence in position 1"
        err = Semigroups.Errors.translate_duplicate_error(msg)
        @test err isa ArgumentError
        @test occursin("duplicate image value 3", err.msg)  # 2 + 1
        @test occursin("position 4", err.msg)  # 3 + 1
        @test occursin("position 2", err.msg)  # 1 + 1

        @test Semigroups.Errors.translate_duplicate_error("unrelated") === nothing
    end

    @testset "Size mismatch error translation" begin
        msg = "domain and image size mismatch, domain has size 5 but image has size 3"
        err = Semigroups.Errors.translate_size_mismatch_error(msg)
        @test err isa DimensionMismatch
        @test occursin("domain", err.msg)
        @test occursin("image", err.msg)
        @test occursin("5", err.msg)
        @test occursin("3", err.msg)

        @test Semigroups.Errors.translate_size_mismatch_error("unrelated") === nothing
    end

    @testset "UNDEFINED error translation" begin
        msg = "must not contain UNDEFINED in position 2"
        err = Semigroups.Errors.translate_undefined_error(msg)
        @test err isa ArgumentError
        @test occursin("position 3", err.msg)  # 2 + 1

        @test Semigroups.Errors.translate_undefined_error("unrelated") === nothing
    end

    @testset "translate_libsemigroups_error dispatch" begin
        # Bounds error
        ex = ErrorException(
            "/path:1:func: image value out of bounds, expected value in [0, 3), found 5 in position 2",
        )
        translated = Semigroups.Errors.translate_libsemigroups_error(ex)
        @test translated isa DomainError

        # Duplicate error
        ex = ErrorException(
            "duplicate image value, found 2 in position 3, first occurrence in position 1",
        )
        translated = Semigroups.Errors.translate_libsemigroups_error(ex)
        @test translated isa ArgumentError

        # Size mismatch error
        ex = ErrorException(
            "domain and image size mismatch, domain has size 5 but image has size 3",
        )
        translated = Semigroups.Errors.translate_libsemigroups_error(ex)
        @test translated isa DimensionMismatch

        # Fallback (unknown error)
        ex = ErrorException("some unknown error message")
        translated = Semigroups.Errors.translate_libsemigroups_error(ex)
        @test translated isa ArgumentError
        @test occursin("unknown error", translated.msg)
    end

    @testset "Julia-side transformation errors" begin
        # Zero degree Transf
        @test_throws ArgumentError Transf(Int[])

        # Zero degree PPerm (from images)
        @test_throws ArgumentError PPerm([])

        # Zero degree Perm
        @test_throws ArgumentError Perm(Int[])

        # Invalid permutation (not a bijection)
        @test_throws ArgumentError Perm([1, 1, 2])

        # DimensionMismatch for PPerm with mismatched domain/image
        @test_throws DimensionMismatch PPerm([1, 2], [3], 4)

        # Degree too large
        @test_throws ArgumentError Semigroups._scalar_type_from_degree(2^33)
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
