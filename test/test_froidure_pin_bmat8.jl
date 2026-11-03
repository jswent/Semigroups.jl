# Copyright (c) 2026, James W. Swent
#
# Distributed under the terms of the GPL license version 3.
#
# The full license is in the file LICENSE, distributed with this software.

"""
test_froidure_pin_bmat8.jl - FroidurePin<BMat8> correctness tests

Ported from libsemigroups/tests/test-froidure-pin-bmat8.cpp.
All indices are 1-based (Julia convention).
"""

ReportGuard(false) do

    @testset "FroidurePin<BMat8> correctness" begin

        # A 5x5 boolean matrix that does not belong to any of the semigroups used
        # in testing
        not_in_S = BMat8([
            [1, 0, 0, 1, 1],
            [0, 1, 0, 0, 1],
            [1, 0, 1, 0, 1],
            [0, 0, 1, 0, 1],
            [0, 0, 0, 0, 0],
        ])

        # -----------------------------------------------------------------------
        # Test 010: "regular boolean mat monoid 4 - BMat8" [quick]
        # -----------------------------------------------------------------------
        @testset "010: regular boolean mat monoid 4" begin
            S = FroidurePin(
                BMat8([[0, 1, 0, 0], [1, 0, 0, 0], [0, 0, 1, 0], [0, 0, 0, 1]]),
                BMat8([[0, 1, 0, 0], [0, 0, 1, 0], [0, 0, 0, 1], [1, 0, 0, 0]]),
                BMat8([[1, 0, 0, 0], [0, 1, 0, 0], [0, 0, 1, 0], [1, 0, 0, 1]]),
                BMat8([[1, 0, 0, 0], [0, 1, 0, 0], [0, 0, 1, 0], [0, 0, 0, 0]]),
            )

            @test current_max_word_length(S) == 1
            @test !finished(S)
            @test !started(S)
            @test current_position(S, generator(S, 1) * generator(S, 4)) == UNDEFINED
            @test current_position(S, not_in_S) == UNDEFINED
            @test current_size(S) == 4
            @test current_number_of_rules(S) == 0
            @test current_length(S, 1) == 1
            @test word_length(S, 6) == 2

            @test length(S) == 63904
            @test number_of_idempotents(S) == 2360
            @test current_position(S, [1, 2, 3, 1, 2, 3]) == 379
            @test to_element(S, [1, 2, 3, 1, 2, 3]) ==
                  BMat8([[1, 0, 0, 1], [0, 1, 0, 0], [1, 0, 1, 0], [0, 0, 1, 0]])
            @test current_max_word_length(S) == 21
            @test degree(S) == 8
            @test number_of_generators(S) == 4
            @test generator(S, 1) ==
                  BMat8([[0, 1, 0, 0], [1, 0, 0, 0], [0, 0, 1, 0], [0, 0, 0, 1]])
            @test generator(S, 2) ==
                  BMat8([[0, 1, 0, 0], [0, 0, 1, 0], [0, 0, 0, 1], [1, 0, 0, 0]])
            @test generator(S, 3) ==
                  BMat8([[1, 0, 0, 0], [0, 1, 0, 0], [0, 0, 1, 0], [1, 0, 0, 1]])
            @test generator(S, 4) ==
                  BMat8([[1, 0, 0, 0], [0, 1, 0, 0], [0, 0, 1, 0], [0, 0, 0, 0]])
            @test finished(S)
            @test started(S)
            @test current_position(S, generator(S, 1) * generator(S, 4)) == 8
            @test current_position(S, not_in_S) == UNDEFINED
            @test current_number_of_rules(S) == 13716

            # prefix / suffix / first_letter / final_letter
            @test prefix(S, 1) == UNDEFINED
            @test suffix(S, 1) == UNDEFINED
            @test first_letter(S, 1) == 1
            @test final_letter(S, 1) == 1

            @test batch_size(S) == 8192

            # Lengths
            @test current_length(S, 1) == 1
            @test current_length(S, 8) == 2
            @test current_length(S, 63904) == 21
            @test word_length(S, 8) == 2
            @test word_length(S, 63904) == 21

            # Products
            @test product_by_reduction(S, 1, 4) == 8
            @test fast_product(S, 1, 4) == 8

            for i = 1:4
                @test position_of_generator(S, i) == i
            end

            # Idempotents
            @test !is_idempotent(S, 1)
            @test is_idempotent(S, 4)
            @test !is_idempotent(S, 8)
            @test number_of_rules(S) == 13716

            # Membership and positions
            @test generator(S, 2) in S
            @test !(not_in_S in S)
            @test Semigroups.position(S, generator(S, 2)) == 2
            @test Semigroups.position(S, generator(S, 1) * generator(S, 4)) == 8
            @test Semigroups.position(S, not_in_S) == UNDEFINED

            # Sorted positions (1-based: C++ 18185 → Julia 18186, etc.)
            @test sorted_position(S, not_in_S) == UNDEFINED
            @test sorted_position(S, generator(S, 1)) == 18186
            @test sorted_position(S, generator(S, 4)) == 33067
            @test sorted_position(S, generator(S, 1) * generator(S, 4)) == 18185
            @test to_sorted_position(S, 1) == 18186
            @test to_sorted_position(S, 4) == 33067
            @test to_sorted_position(S, 8) == 18185

            # Element access
            @test S[8] == generator(S, 1) * generator(S, 4)
            @test S[8] == S[1] * S[4]
            @test sorted_at(S, 18186) == S[1]
            @test sorted_at(S, 33067) == S[4]
            @test sorted_at(S, 18185) == generator(S, 1) * generator(S, 4)

            # Cayley graphs
            @test target(right_cayley_graph(S), 1, 4) == 8
            @test target(left_cayley_graph(S), 1, 4) == 8

            # Factorisations
            # NOTE: the C++ overloads taking an element are not wrapped, so we
            # go via position.
            @test minimal_factorisation(S, 379) == [1, 2, 3, 1, 2, 3]
            @test current_length(S, 379) == 6
            @test minimal_factorisation(S, Semigroups.position(S, S[379])) ==
                  [1, 2, 3, 1, 2, 3]
            @test_throws LibsemigroupsError minimal_factorisation(S, 1000000)

            @test factorisation(S, 379) == [1, 2, 3, 1, 2, 3]
            @test current_length(S, 379) == 6
            @test factorisation(S, Semigroups.position(S, S[379])) == [1, 2, 3, 1, 2, 3]
            @test_throws LibsemigroupsError factorisation(S, 1000000)

            # Rules
            rs = rules(S)
            @test rs[1] == ([3, 3] => [3])
            @test rs[2] == ([4, 1] => [1, 4])
            @test rs[3] == ([4, 3] => [4])
            @test length(rs) == number_of_rules(S)
            @test number_of_rules(S) == 13716

            # Position of every element matches iteration order
            pos = 0
            for (i, x) in Base.enumerate(S)
                @test Semigroups.position(S, x) == i
                pos += 1
            end
            @test pos == length(S)

            # Copy - after run
            T = copy(S)
            @test length(T) == 63904
            @test number_of_idempotents(T) == 2360
            @test current_position(T, [1, 2, 3, 1, 2, 3]) == 379
            @test to_element(T, [1, 2, 3, 1, 2, 3]) ==
                  BMat8([[1, 0, 0, 1], [0, 1, 0, 0], [1, 0, 1, 0], [0, 0, 1, 0]])
            @test current_max_word_length(T) == 21
            @test degree(T) == 8
            @test number_of_generators(T) == 4
            @test generator(T, 1) ==
                  BMat8([[0, 1, 0, 0], [1, 0, 0, 0], [0, 0, 1, 0], [0, 0, 0, 1]])
            @test generator(T, 2) ==
                  BMat8([[0, 1, 0, 0], [0, 0, 1, 0], [0, 0, 0, 1], [1, 0, 0, 0]])
            @test generator(T, 3) ==
                  BMat8([[1, 0, 0, 0], [0, 1, 0, 0], [0, 0, 1, 0], [1, 0, 0, 1]])
            @test generator(T, 4) ==
                  BMat8([[1, 0, 0, 0], [0, 1, 0, 0], [0, 0, 1, 0], [0, 0, 0, 0]])
            @test finished(T)
            @test started(T)
        end

        # -----------------------------------------------------------------------
        # Test 011: "exception zero generators given - BMat8" [quick]
        # -----------------------------------------------------------------------
        @testset "011: no exception zero generators" begin
            # The C++ library accepts empty generator sets; the Julia wrapper
            # currently requires at least one generator, so we test that
            # constraint.
            @test_throws ErrorException FroidurePin(BMat8[])
        end

        # -----------------------------------------------------------------------
        # Test 012: "exception to_element - BMat8" [quick]
        # -----------------------------------------------------------------------
        @testset "012: exception to_element" begin
            S = FroidurePin(
                BMat8([[0, 1, 0, 0], [1, 0, 0, 0], [0, 0, 1, 0], [0, 0, 0, 1]]),
                BMat8([[0, 1, 0, 0], [0, 0, 1, 0], [0, 0, 0, 1], [1, 0, 0, 0]]),
                BMat8([[1, 0, 0, 0], [0, 1, 0, 0], [0, 0, 1, 0], [1, 0, 0, 1]]),
                BMat8([[1, 0, 0, 0], [0, 1, 0, 0], [0, 0, 1, 0], [0, 0, 0, 0]]),
            )

            @test !contains_one(S)
            @test_throws LibsemigroupsError to_element(S, Int[])
            @test to_element(S, [1]) isa BMat8
            @test to_element(S, [1, 4, 1, 4, 2]) isa BMat8
            @test_throws LibsemigroupsError to_element(S, [1, 2, 1, 5])
        end

        # -----------------------------------------------------------------------
        # Test 013: "exception prefix - BMat8" [quick]
        # -----------------------------------------------------------------------
        @testset "013: exception prefix" begin
            S = FroidurePin(
                BMat8([[0, 1, 0, 0], [1, 0, 0, 0], [0, 0, 1, 0], [0, 0, 0, 1]]),
                BMat8([[0, 1, 0, 0], [0, 0, 1, 0], [0, 0, 0, 1], [1, 0, 0, 0]]),
                BMat8([[1, 1, 0, 0], [1, 0, 1, 0], [0, 1, 1, 1], [0, 1, 1, 1]]),
            )

            for i = 1:length(S)
                @test_nowarn prefix(S, i)
                @test_throws LibsemigroupsError prefix(S, i + length(S))
            end
        end

        # -----------------------------------------------------------------------
        # Test 014: "exception first_letter - BMat8" [quick]
        # -----------------------------------------------------------------------
        @testset "014: exception first_letter" begin
            S = FroidurePin(
                BMat8([[0, 1, 0, 0], [1, 0, 0, 0], [0, 0, 1, 0], [0, 0, 0, 1]]),
                BMat8([[0, 1, 0, 0], [0, 0, 1, 0], [0, 0, 0, 1], [1, 0, 0, 0]]),
                BMat8([[1, 1, 0, 0], [1, 0, 1, 0], [0, 1, 1, 1], [0, 1, 1, 1]]),
            )

            for i = 1:length(S)
                @test first_letter(S, i) isa Integer
                @test_throws LibsemigroupsError first_letter(S, i + length(S))
            end
        end

        # -----------------------------------------------------------------------
        # Test 015: "exception current_length - BMat8" [quick]
        # -----------------------------------------------------------------------
        @testset "015: exception current_length" begin
            S = FroidurePin(
                BMat8([[0, 1, 0, 0], [1, 0, 0, 0], [0, 0, 1, 0], [0, 0, 0, 1]]),
                BMat8([[0, 1, 0, 0], [0, 0, 1, 0], [0, 0, 0, 1], [1, 0, 0, 0]]),
                BMat8([[1, 1, 0, 0], [1, 0, 1, 0], [0, 1, 1, 1], [0, 1, 1, 1]]),
            )

            for i = 1:length(S)
                @test current_length(S, i) isa Integer
                @test_throws LibsemigroupsError current_length(S, i + length(S))
            end
        end

        # -----------------------------------------------------------------------
        # Test 016: "exception product_by_reduction - BMat8" [quick]
        # -----------------------------------------------------------------------
        @testset "016: exception product_by_reduction" begin
            S = FroidurePin(
                BMat8([[0, 1, 0, 0], [1, 0, 0, 0], [0, 0, 1, 0], [0, 0, 0, 1]]),
                BMat8([[1, 1, 0, 0], [1, 0, 1, 0], [0, 1, 1, 1], [0, 1, 1, 1]]),
            )

            n = length(S)
            for i = 2:n
                for j = 2:n
                    @test product_by_reduction(S, i, j) isa Integer
                    @test_throws LibsemigroupsError product_by_reduction(S, i + n, j)
                    @test_throws LibsemigroupsError product_by_reduction(S, i, j + n)
                    @test_throws LibsemigroupsError product_by_reduction(S, i + n, j + n)
                end
            end
        end

        # -----------------------------------------------------------------------
        # Test 017: "exception fast_product - BMat8" [quick]
        # -----------------------------------------------------------------------
        @testset "017: exception fast_product" begin
            S = FroidurePin(
                BMat8([[0, 1, 0, 0], [1, 0, 0, 0], [0, 0, 1, 0], [0, 0, 0, 1]]),
                BMat8([[1, 1, 0, 0], [1, 0, 1, 0], [0, 1, 1, 1], [0, 1, 1, 1]]),
            )

            n = length(S)
            for i = 2:n
                for j = 2:n
                    @test fast_product(S, i, j) isa Integer
                    @test_throws LibsemigroupsError fast_product(S, i + n, j)
                    @test_throws LibsemigroupsError fast_product(S, i, j + n)
                    @test_throws LibsemigroupsError fast_product(S, i + n, j + n)
                end
            end
        end

        # -----------------------------------------------------------------------
        # Test 018: "exception is_idempotent - BMat8" [quick]
        # -----------------------------------------------------------------------
        @testset "018: exception is_idempotent" begin
            S = FroidurePin(
                BMat8([[0, 1, 0, 0], [1, 0, 0, 0], [0, 0, 1, 0], [0, 0, 0, 1]]),
                BMat8([[0, 1, 0, 0], [0, 0, 1, 0], [0, 0, 0, 1], [1, 0, 0, 0]]),
                BMat8([[1, 0, 0, 0], [0, 1, 0, 0], [0, 0, 1, 0], [1, 0, 0, 1]]),
                BMat8([[1, 0, 0, 0], [0, 1, 0, 0], [0, 0, 1, 0], [0, 0, 0, 0]]),
            )

            @test length(S) == 63904

            nr = count(i -> is_idempotent(S, i), 1:length(S))
            @test nr == number_of_idempotents(S)
            @test nr == 2360
            @test length(idempotents(S)) == 2360

            @test_throws LibsemigroupsError is_idempotent(S, 63905)

            # Skip the first 10000 normal forms, then take 20
            nf = normal_forms(S)
            @test nf[10001:10020] == [
                [2, 2, 1, 3, 4, 2, 3, 2, 3, 2],
                [2, 2, 1, 3, 4, 2, 4, 2, 3, 2],
                [2, 2, 1, 4, 2, 2, 2, 3, 1, 3],
                [2, 2, 1, 4, 2, 2, 3, 1, 3, 2],
                [2, 2, 1, 4, 2, 2, 3, 2, 3, 1],
                [2, 2, 1, 4, 2, 2, 3, 2, 3, 4],
                [2, 2, 1, 4, 2, 3, 1, 2, 3, 1],
                [2, 2, 1, 4, 2, 3, 1, 2, 3, 2],
                [2, 2, 1, 4, 2, 3, 1, 3, 2, 1],
                [2, 2, 1, 4, 2, 3, 1, 3, 2, 2],
                [2, 2, 1, 4, 2, 3, 1, 3, 2, 3],
                [2, 2, 1, 4, 2, 3, 2, 2, 2, 3],
                [2, 2, 1, 4, 2, 3, 2, 2, 3, 1],
                [2, 2, 1, 4, 2, 3, 2, 2, 3, 2],
                [2, 2, 1, 4, 2, 3, 2, 2, 4, 2],
                [2, 2, 1, 4, 2, 3, 2, 3, 1, 2],
                [2, 2, 1, 4, 2, 3, 2, 3, 2, 1],
                [2, 2, 1, 4, 2, 3, 2, 3, 2, 2],
                [2, 2, 1, 4, 2, 3, 2, 3, 2, 3],
                [2, 2, 1, 4, 2, 3, 2, 3, 2, 4],
            ]
        end

        # -----------------------------------------------------------------------
        # Test 019: "copy constructor - BMat8" [quick]
        # -----------------------------------------------------------------------
        @testset "019: copy constructor" begin
            gens = [
                BMat8([[0, 1, 0, 0], [1, 0, 0, 0], [0, 0, 1, 0], [0, 0, 0, 1]]),
                BMat8([[0, 1, 0, 0], [0, 0, 1, 0], [0, 0, 0, 1], [1, 0, 0, 0]]),
                BMat8([[1, 0, 0, 0], [0, 1, 0, 0], [0, 0, 1, 0], [1, 0, 0, 1]]),
                BMat8([[1, 0, 0, 0], [0, 1, 0, 0], [0, 0, 1, 0], [0, 0, 0, 0]]),
            ]

            @testset "fully enumerated" begin
                S = FroidurePin(gens)
                @test length(S) == 63904
                T = copy(S)
                @test length(T) == 63904
            end

            @testset "partially enumerated" begin
                S = FroidurePin(gens)
                enumerate!(S, 8192)
                @test !finished(S)
                T = copy(S)
                @test length(T) == 63904
            end

            @testset "not enumerated" begin
                S = FroidurePin(gens)
                T = copy(S)
                @test length(T) == 63904
            end
        end

        # -----------------------------------------------------------------------
        # Test 020: "cbegin/end_rules - BMat8" [quick]
        # -----------------------------------------------------------------------
        @testset "020: rules" begin
            S = FroidurePin(
                BMat8([[1, 0, 0, 0], [1, 0, 0, 0], [1, 0, 0, 0], [1, 0, 0, 0]]),
                BMat8([[0, 1, 0, 0], [0, 1, 0, 0], [0, 1, 0, 0], [0, 1, 0, 0]]),
                BMat8([[0, 0, 1, 0], [0, 0, 1, 0], [0, 0, 1, 0], [0, 0, 1, 0]]),
                BMat8([[0, 0, 0, 1], [0, 0, 0, 1], [0, 0, 0, 1], [0, 0, 0, 1]]),
            )
            @test length(S) == 4
            @test rules(S) == [
                [1, 1] => [1],
                [1, 2] => [2],
                [1, 3] => [3],
                [1, 4] => [4],
                [2, 1] => [1],
                [2, 2] => [2],
                [2, 3] => [3],
                [2, 4] => [4],
                [3, 1] => [1],
                [3, 2] => [2],
                [3, 3] => [3],
                [3, 4] => [4],
                [4, 1] => [1],
                [4, 2] => [2],
                [4, 3] => [3],
                [4, 4] => [4],
            ]
        end

        # Regression: returning BMat8 by value from FroidurePin
        #
        # This used to segfault because the IsMirroredType<BMat8> specialisation
        # was only visible in bmat8.cpp, so froidure-pin.cpp wrapped BMat8 as a
        # mirrored type. Every function returning a BMat8 is regression tested.
        @testset "regression: BMat8 returned by value" begin
            gens = [
                BMat8([[0, 1, 0, 0], [1, 0, 0, 0], [0, 0, 1, 0], [0, 0, 0, 1]]),
                BMat8([[0, 1, 0, 0], [0, 0, 1, 0], [0, 0, 0, 1], [1, 0, 0, 0]]),
                BMat8([[1, 0, 0, 0], [0, 1, 0, 0], [0, 0, 1, 0], [1, 0, 0, 1]]),
                BMat8([[1, 0, 0, 0], [0, 1, 0, 0], [0, 0, 1, 0], [0, 0, 0, 0]]),
            ]
            S = FroidurePin(gens)
            @test S isa FroidurePin{BMat8}

            # generator / getindex / sorted_at / to_element
            for i = 1:4
                @test generator(S, i) == gens[i]
                @test S[i] == gens[i]
            end
            @test sorted_at(S, 1) == BMat8(0)
            @test to_element(S, [1, 2]) == gens[1] * gens[2]

            # Returned values are usable and round-trip through position
            for i in (1, 100, 10000, length(S))
                x = S[i]
                @test x in S
                @test Semigroups.position(S, x) == i
            end

            # Collections of elements
            @test all(x -> x * x == x, idempotents(S))
            @test length(sorted_elements(S)) == 63904

            # Returned values survive the FroidurePin being garbage collected
            xs = [S[i] for i = 1:100]
            T = copy(S)
            S = nothing
            GC.gc()
            @test all(T[i] == xs[i] for i = 1:100)
        end

    end  # @testset "FroidurePin<BMat8>"

end  # ReportGuard(false)
