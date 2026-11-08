# Copyright (c) 2026, James W. Swent
# Distributed under the terms of the GPL license version 3.
# OpenAI Codex assisted with representation and ownership regression tests.

using Test
using Semigroups

@testset "String presentations" begin
    @testset "representation, letters, and independent copies" begin
        p = Presentation(SubString("_ba_", 2, 3))
        @test p isa Presentation{String}
        @test alphabet(p) == "ba"
        @test letter(p, 1) === 'b'
        @test index_of(p, 'a') == 2
        @test in_alphabet(p, 'b')
        @test !in_alphabet(p, 'c')
        @test rules(p) isa Vector{Tuple{String,String}}
        @test isempty(rules(p))

        add_rule!(p, SubString("_bab_", 2, 4), "b")
        @test rule(p, 1) == ("bab", "b")
        @test rules(p) == [("bab", "b")]
        @test length_of(p) == 4
        @test contains_rule(p, "bab", "b")
        @test index_rule(p, "bab", "b") == 1
        @test index_rule(p, "aaa", "b") === UNDEFINED

        q = copy(p)
        r = deepcopy(p)
        @test q == r == p
        @test hash(q) == hash(p)
        clear_rules!(q)
        add_generator!(r, 'c')
        @test rules(p) == [("bab", "b")]
        @test alphabet(p) == "ba"

        numeric = Presentation([1, 2])
        @test numeric isa Presentation{Vector{Int}}
        @test p != numeric
        @test_throws ArgumentError add_rule!(p, [1], [2])
        @test_throws ArgumentError add_rule!(numeric, "a", "b")
        @test_throws ArgumentError add_rules!(p, numeric)
        @test_throws ArgumentError index_of(p, 1)
        @test_throws ArgumentError index_of(numeric, 'a')
        for invalid in (0, UInt(0), typemin(Int), typemax(UInt))
            @test_throws InexactError set_alphabet!(numeric, [invalid])
        end
        @test alphabet(numeric) == [1, 2]
        set_alphabet!(numeric, [typemax(Int)])
        @test alphabet(numeric) == [typemax(Int)]
    end

    @testset "ASCII transport and validation before mutation" begin
        p = Presentation("a\0")
        @test alphabet(p) == "a\0"
        @test letter(p, 2) === '\0'
        @test index_of(p, '\0') == 2
        add_rule!(p, "a\0a", "\0")
        @test rules(p) == [("a\0a", "\0")]
        @test length_of(p) == 4

        before = copy(p)
        @test_throws ArgumentError set_alphabet!(p, "aα")
        @test_throws ArgumentError add_rule!(p, "α", "a")
        @test_throws ArgumentError add_rule_no_checks!(p, "α", "a")
        @test_throws ArgumentError add_generator!(p, 'α')
        @test_throws ArgumentError add_rule!(p, String(UInt8[0xff]), "a")
        @test p == before
        @test_throws LibsemigroupsError add_rule!(p, "b", "a")
        @test_throws LibsemigroupsError add_rule!(p, "", "a")

        set_contains_empty_word!(p, true)
        add_rule!(p, "\0\0", "")
        @test rule_rhs(p, 2) == ""
        @test contains_empty_word(copy(p))
        @test_throws LibsemigroupsError Presentation("aa")
    end

    @testset "renaming, replacement, and rule helpers" begin
        p = Presentation("ab")
        add_rule!(p, "aba", "a")
        change_alphabet!(p, "xy")
        @test alphabet(p) == "xy"
        @test rules(p) == [("xyx", "x")]
        old_word = rule_lhs(p, 1)
        replace_subword!(p, "xy", "x")
        @test old_word == "xyx"
        @test rules(p) == [("xx", "x")]
        replace_word!(p, "xx", "xy")
        @test rules(p) == [("xy", "x")]
        reverse!(p)
        @test rules(p) == [("yx", "x")]
        reverse!(p)

        # Setting an alphabet and renaming it have different contracts.
        set_alphabet!(p, "uv")
        @test rules(p) == [("xy", "x")]
        @test_throws LibsemigroupsError throw_if_bad_rules(p)
        set_alphabet!(p, "xy")
        normalize_alphabet!(p)
        @test alphabet(p) == "ab"
        @test rules(p) == [("ab", "a")]
        # The pinned native predicate tests zero-based byte values, whereas
        # normalization uses the human-readable letter order for strings.
        @test !is_normalized(p)
        @test is_normalized(Presentation("\0\x01"))

        z = replace_word_with_new_generator!(p, "ab")
        @test z === 'c'
        @test alphabet(p) == "abc"
        @test is_rule(p, "c", "a")
        @test is_rule(p, "c", "ab")
        @test first_unused_letter(p) === 'd'
        @test add_generator!(p) === 'd'

        q = Presentation("abcde")
        add_identity_rules!(q, 'e')
        add_zero_rules!(q, 'c')
        @test is_rule(q, "ae", "a")
        @test is_rule(q, "ac", "c")
        throw_if_bad_alphabet_or_rules(q)
        init!(q)
        @test isempty(q)
        @test alphabet(q) == ""
        @test rules(q) isa Vector{Tuple{String,String}}
    end

    @testset "inverse presentations preserve representation" begin
        p = Presentation("aA")
        set_contains_empty_word!(p, true)
        add_inverse_rules!(p, "Aa")
        ip = InversePresentation(p)
        @test ip isa InversePresentation{String}
        @test ip isa Presentation{String}
        set_inverses!(ip, "Aa")
        @test inverses(ip) == "Aa"
        @test inverse_of(ip, 'a') === 'A'
        @test inverse_of(ip, 'A') === 'a'
        throw_if_bad_alphabet_rules_or_inverses(ip)
        q = copy(ip)
        r = deepcopy(ip)
        @test q == r == ip
        @test q isa InversePresentation{String}
        @test isequal(q, ip)
        @test hash(q) == hash(ip)
        base = Presentation(ip)
        @test base == p
        @test base != ip
        @test ip != base
        @test !isequal(base, ip)
        @test !isequal(ip, base)
        set_inverses!(q, "aA")
        @test q != ip
        @test !isequal(q, ip)
        @test length(Set([base, ip, q, r])) == 3
        @test inverses(ip) == "Aa"
        @test_throws ArgumentError set_inverses!(ip, [2, 1])
        @test_throws LibsemigroupsError set_inverses!(ip, "aa")

        change_alphabet!(ip, "xy")
        @test alphabet(ip) == "xy"
        @test inverses(ip) == "yx"
        @test inverse_of(ip, 'x') === 'y'
        throw_if_bad_alphabet_rules_or_inverses(ip)
        before = copy(ip)
        @test_throws LibsemigroupsError change_alphabet!(ip, "xx")
        @test ip == before
        normalize_alphabet!(ip)
        @test alphabet(ip) == "ab"
        @test inverses(ip) == "ba"
        @test inverse_of(ip, 'a') === 'b'
        init!(ip)
        @test isempty(ip)
        @test inverses(ip) == ""
        @test !contains_empty_word(ip)

        numeric = InversePresentation(Presentation([3, 5]))
        set_inverses!(numeric, [5, 3])
        change_alphabet!(numeric, [10, 20])
        @test inverses(numeric) == [20, 10]
        normalize_alphabet!(numeric)
        @test inverses(numeric) == [2, 1]
        @test inverse_of(numeric, 1) == 2
        init!(numeric)
        @test isempty(numeric)
        @test isempty(inverses(numeric))
    end

    @testset "generated alphabets stay in ASCII" begin
        p = Presentation{String}()
        set_alphabet!(p, 3)
        @test alphabet(p) == "abc"
        before = copy(p)
        @test_throws ArgumentError set_alphabet!(p, 32)
        @test p == before

        ascii_alphabet = String(UInt8[i for i = 0:127])
        p = Presentation(ascii_alphabet)
        @test alphabet(p) == ascii_alphabet
        before = copy(p)
        @test_throws ArgumentError first_unused_letter(p)
        @test_throws ArgumentError add_generator!(p)
        @test_throws ArgumentError replace_word_with_new_generator!(p, "a")
        @test p == before
    end
end
