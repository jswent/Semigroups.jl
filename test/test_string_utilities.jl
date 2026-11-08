# Copyright (c) 2026, James W. Swent
#
# Distributed under the terms of the GPL license version 3.
# Prepared with OpenAI Codex assistance for string representation coverage.

using Test
using Semigroups

@testset verbose = true "String word utilities" begin
    @testset "explicit alphabet conversions" begin
        to_word = ToWord("ba")
        to_string = ToString("ba")
        @test to_word("abba") == [2, 1, 1, 2]
        @test to_string([2, 1, 1, 2]) == "abba"
        @test to_word("") == Int[]
        @test to_string(Int[]) == ""
        @test to_word(SubString("xabbay", 2, 5)) == [2, 1, 1, 2]
        @test to_string(view([2, 1, 1, 2, 1], 1:4)) == "abba"
        @test to_string(to_word("baba")) == "baba"

        # An explicit empty alphabet denotes no generators, not the backend's
        # implicit human-readable alphabet.
        @test ToWord("")("") == Int[]
        @test ToString("")(Int[]) == ""
        @test_throws ArgumentError ToWord("")("a")
        @test_throws ArgumentError ToString("")([1])
        @test_throws ArgumentError ToWord("ba")("c")
        @test_throws ArgumentError ToString("ba")([0])
        @test_throws ArgumentError ToString("ba")([3])
        @test_throws ArgumentError ToWord("bb")
        @test_throws ArgumentError ToString("bb")
        @test_throws ArgumentError ToWord("αb")
        @test_throws ArgumentError ToString("αb")

        @test ToWord("a\0")("\0a\0") == [2, 1, 2]
        @test ToString("a\0")([2, 1, 2]) == "\0a\0"
    end

    @testset "range order, epsilon, and owning outputs" begin
        r = StringRange("ba")
        @test alphabet(r) == "ba"
        @test set_min!(r, 1) === r
        @test set_max!(r, 3) === r
        @test count(r) == 6
        @test eltype(r) == String
        @test collect(r) == ["b", "a", "bb", "ba", "ab", "aa"]
        @test at_end(r)

        r = StringRange("ba")
        set_min!(r, 1)
        set_max!(r, 3)
        saved = get(r)
        next!(r)
        @test saved == "b"
        @test get(r) == "a"
        copied = copy(r)
        @test get(deepcopy(r)) == "a"
        next!(r)
        @test get(copied) == "a"

        bounds = StringRange("ba")
        set_first!(bounds, "a")
        set_last!(bounds, "bb")
        @test first_word(bounds) == "a"
        @test last_word(bounds) == "bb"
        @test_throws ArgumentError set_first!(bounds, "c")
        @test first_word(bounds) == "a"
        @test collect(bounds) == ["a"]

        r = StringRange("a\0")
        set_min!(r, 0)
        set_max!(r, 2)
        @test collect(r) == ["", "a", "\0"]
        @test_throws ArgumentError StringRange("α")
        @test_throws ArgumentError set_first!(StringRange(""), "a")
        @test_throws ArgumentError set_last!(StringRange("ba"), "c")
    end

    @testset "string comparisons use character order" begin
        @test lex_less("", "a")
        @test lex_less("a", "b")
        @test !lex_less("b", "a")
        @test !lex_less("ab", "ab")
        @test lex_less(SubString("xab", 2, 3), "ac")
        @test shortlex_less("b", "aa")
        @test !shortlex_less("aa", "b")
        @test recursive_path_less("a", "b")
        @test lex_less("\0", "a")
        @test_throws ArgumentError lex_less("α", "b")
        @test_throws ArgumentError shortlex_less("a", "β")
    end

    @testset "weighted comparisons use ASCII byte indices" begin
        weights = ones(Int, 128)
        weights[Int('a')+1] = 3
        weights[Int('b')+1] = 1
        @test weighted_shortlex_less("bb", "a", weights)
        @test !weighted_shortlex_less("a", "bb", weights)
        @test weighted_lex_less("b", "a", weights)
        @test !weighted_lex_less("a", "b", weights)
        @test weighted_shortlex_less("\0", "a", weights)
        @test_throws ArgumentError weighted_lex_less("a", "b", [-1])
        @test_throws Semigroups.Errors.LibsemigroupsError weighted_shortlex_less(
            "a",
            "b",
            [1],
        )
    end

    @testset "graph congruences align generated string alphabets" begin
        for n in (27, 31)
            expected = String(UInt8[UInt8('a') + i for i = 0:(n-1)])
            final_letter = string(last(expected))
            graph = WordGraph(2, n)
            for node = 1:2, letter = 1:n
                target!(graph, node, letter, 2)
            end
            congruence = Semigroups.to(Congruence{String}, twosided, graph)
            @test alphabet(presentation(congruence)) == expected
            @test number_of_classes(congruence) == 1
            @test Semigroups.reduce(congruence, final_letter) == "a"
            @test Semigroups.reduce(copy(congruence), final_letter) == "a"

            # The FroidurePin conversion has the same native alphabet mismatch.
            fp = FroidurePin([Transf([1]) for _ = 1:n])
            from_fp =
                Semigroups.to(Congruence{String}, twosided, fp, right_cayley_graph(fp))
            @test alphabet(presentation(from_fp)) == expected
            @test number_of_classes(from_fp) == 1
            @test Semigroups.reduce(from_fp, final_letter) == "a"
        end
    end

    @testset "random strings" begin
        @test random_word("ab", 0) == ""
        w = random_word("ab", 32)
        @test w isa String
        @test length(w) == 32
        @test all(c -> c in ('a', 'b'), w)
        @test random_word("\0", 4) == "\0\0\0\0"
        @test_throws ArgumentError random_word("α", 2)
    end
end
