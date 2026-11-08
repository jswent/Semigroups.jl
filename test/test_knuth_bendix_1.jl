# Copyright (c) 2026, James W. Swent
#
# Distributed under the terms of the GPL license version 3.
#
# The full license is in the file LICENSE, distributed with this software.

"""
test_knuth_bendix_1.jl - Ports of libsemigroups test-knuth-bendix-1.cpp

The upstream file mostly tests `KnuthBendix<std::string, *>`. Semigroups.jl
currently exposes the `word_type`/`RewriteTrie` instantiation, so these tests
translate each C++ string alphabet to 1-based Julia word vectors while keeping
the C++ test numbering.
"""

using Test
using Semigroups
using Dates

function _kb1_word(alphabet::AbstractString, s::AbstractString)
    letters = collect(alphabet)
    return [something(findfirst(==(c), letters)) for c in s]
end

function _kb1_words(alphabet::AbstractString, strings)
    return [_kb1_word(alphabet, s) for s in strings]
end

function _kb1_add_rule!(p::Presentation, alphabet::AbstractString, lhs, rhs)
    add_rule_no_checks!(p, _kb1_word(alphabet, lhs), _kb1_word(alphabet, rhs))
    return p
end

_kb1_cword(xs::Integer...) = [Int(x) + 1 for x in xs]
_kb1_cword(xs::AbstractVector{<:Integer}) = [Int(x) + 1 for x in xs]

function _kb1_add_cpp_rule!(p::Presentation, lhs, rhs)
    add_rule_no_checks!(p, _kb1_cword(lhs), _kb1_cword(rhs))
    return p
end

function _kb1_presentation(alphabet::AbstractString, rules; empty_word::Bool = false)
    p = Presentation()
    empty_word && set_contains_empty_word!(p, true)
    set_alphabet!(p, length(collect(alphabet)))
    for (lhs, rhs) in rules
        _kb1_add_rule!(p, alphabet, lhs, rhs)
    end
    return p
end

function _kb1_words_of_length(n::Integer, len::Integer)
    len == 0 && return [Int[]]
    prev = _kb1_words_of_length(n, len - 1)
    return [[word; a] for word in prev for a = 1:n]
end

function _kb1_normal_forms_between(
    kb::KnuthBendix,
    alphabet_size::Integer,
    min_len::Integer,
    max_len::Integer,
)
    result = Vector{Int}[]
    for len = min_len:max_len
        for w in _kb1_words_of_length(alphabet_size, len)
            Semigroups.reduce(kb, w) == w && push!(result, w)
        end
    end
    return result
end

function _kb1_expect_normal_forms(
    kb::KnuthBendix,
    alphabet::AbstractString,
    min_len::Integer,
    max_len::Integer,
    expected,
)
    @test _kb1_normal_forms_between(kb, length(collect(alphabet)), min_len, max_len) ==
          _kb1_words(alphabet, expected)
end

function _kb1_same_presentation(p::Presentation, q::Presentation)
    return contains_empty_word(p) == contains_empty_word(q) &&
           Semigroups.alphabet(p) == Semigroups.alphabet(q) &&
           rules(p) == rules(q)
end

function _kb1_number_of_edges(g)
    count = 0
    for source = 1:number_of_nodes(g), label = 1:out_degree(g)
        is_undefined(target(g, source, label)) || (count += 1)
    end
    return count
end

function _kb1_is_acyclic(g)
    state = zeros(Int, number_of_nodes(g))

    function visit(v)
        state[v] == 1 && return false
        state[v] == 2 && return true
        state[v] = 1
        for label = 1:out_degree(g)
            t = target(g, v, label)
            if !is_undefined(t) && !visit(t)
                return false
            end
        end
        state[v] = 2
        return true
    end

    return all(v -> state[v] == 2 || visit(v), 1:number_of_nodes(g))
end

function _kb1_path_count(g, min_len::Integer, max_len::Integer; source::Integer = 1)
    counts = zeros(BigInt, number_of_nodes(g))
    counts[source] = 1
    total = min_len == 0 ? big(1) : big(0)

    for len = 1:max_len
        next_counts = zeros(BigInt, number_of_nodes(g))
        for v = 1:number_of_nodes(g)
            iszero(counts[v]) && continue
            for label = 1:out_degree(g)
                t = target(g, v, label)
                is_undefined(t) || (next_counts[t] += counts[v])
            end
        end
        len >= min_len && (total += sum(next_counts))
        counts = next_counts
    end

    return total
end

function _kb1_paths_take_from_successors(
    successors,
    n::Integer;
    source::Integer = 1,
    skip_empty::Bool = true,
)
    nodes = [source]
    words = [Int[]]
    result = Vector{Int}[]
    head = 1

    while length(result) < n
        head <= length(nodes) || error("not enough paths in graph")
        v = nodes[head]
        w = words[head]
        head += 1

        if !(skip_empty && isempty(w))
            push!(result, w)
            length(result) == n && break
        end

        for (label, t) in successors(v)
            push!(nodes, t)
            push!(words, [w; label])
        end
    end

    return result
end

function _kb1_paths_take(g, n::Integer; source::Integer = 1, skip_empty::Bool = true)
    return _kb1_paths_take_from_successors(n; source, skip_empty) do v
        edges = Tuple{Int,Int}[]
        for label = 1:out_degree(g)
            t = target(g, v, label)
            is_undefined(t) || push!(edges, (label, Int(t)))
        end
        return edges
    end
end

function _kb1_paths_take_rows(
    rows,
    n::Integer;
    source::Integer = 1,
    skip_empty::Bool = true,
)
    degree = maximum(length, rows)
    return _kb1_paths_take_from_successors(n; source, skip_empty) do v
        row = rows[v]
        edges = Tuple{Int,Int}[]
        for label = 1:degree
            if label <= length(row)
                t = row[label]
                t === nothing || push!(edges, (label, Int(t) + 1))
            end
        end
        return edges
    end
end

@testset verbose = true "KnuthBendix test-knuth-bendix-1.cpp" begin
    ReportGuard(false)

    @testset "000: confluent fp semigroup 1 (infinite)" begin
        alphabet = "abc"
        p = _kb1_presentation(
            alphabet,
            [
                ("ab", "ba"),
                ("ac", "ca"),
                ("aa", "a"),
                ("ac", "a"),
                ("ca", "a"),
                ("bb", "bb"),
                ("bc", "cb"),
                ("bbb", "b"),
                ("bc", "b"),
                ("cb", "b"),
                ("a", "b"),
            ],
        )

        kb = KnuthBendix(twosided, p)

        @test number_of_active_rules(kb) == 0
        @test number_of_pending_rules(kb) == 10
        @test confluent(kb)
        @test Semigroups.reduce(kb, _kb1_word(alphabet, "ca")) == _kb1_word(alphabet, "a")
        @test Semigroups.reduce(kb, _kb1_word(alphabet, "ac")) == _kb1_word(alphabet, "a")
        @test Semigroups.contains(kb, _kb1_word(alphabet, "ca"), _kb1_word(alphabet, "a"))
        @test Semigroups.contains(kb, _kb1_word(alphabet, "ac"), _kb1_word(alphabet, "a"))
        @test number_of_classes(kb) == POSITIVE_INFINITY
        _kb1_expect_normal_forms(kb, alphabet, 1, 4, ["a", "c", "cc", "ccc", "cccc"])
    end

    @testset "001: confluent fp semigroup 2 (infinite)" begin
        alphabet = "abc"
        p = _kb1_presentation(
            alphabet,
            [
                ("ac", "ca"),
                ("aa", "a"),
                ("ac", "a"),
                ("ca", "a"),
                ("bb", "bb"),
                ("bc", "cb"),
                ("bbb", "b"),
                ("bc", "b"),
                ("cb", "b"),
                ("a", "b"),
            ],
        )

        kb = KnuthBendix(twosided, p)

        @test confluent(kb)
        @test number_of_active_rules(kb) == 4
        _kb1_expect_normal_forms(kb, alphabet, 1, 4, ["a", "c", "cc", "ccc", "cccc"])
        @test number_of_classes(kb) == POSITIVE_INFINITY
    end

    @testset "002: confluent fp semigroup 3 (infinite)" begin
        alphabet = "012"
        p = _kb1_presentation(
            alphabet,
            [
                ("01", "10"),
                ("02", "20"),
                ("00", "0"),
                ("02", "0"),
                ("20", "0"),
                ("11", "11"),
                ("12", "21"),
                ("111", "1"),
                ("12", "1"),
                ("21", "1"),
                ("0", "1"),
            ],
        )

        kb = KnuthBendix(twosided, p)

        @test number_of_active_rules(kb) == 0
        @test number_of_pending_rules(kb) == 10
        @test confluent(kb)
        @test number_of_active_rules(kb) == 4
        @test number_of_classes(kb) == POSITIVE_INFINITY
        _kb1_expect_normal_forms(kb, alphabet, 1, 1, ["0", "2"])
        _kb1_expect_normal_forms(
            kb,
            alphabet,
            1,
            11,
            [
                "0",
                "2",
                "22",
                "222",
                "2222",
                "22222",
                "222222",
                "2222222",
                "22222222",
                "222222222",
                "2222222222",
                "22222222222",
            ],
        )
    end

    @testset "003: non-confluent example wikipedia" begin
        alphabet = "01"
        p = _kb1_presentation(
            alphabet,
            [("000", ""), ("111", ""), ("010101", "")],
            empty_word = true,
        )

        kb = KnuthBendix(twosided, p)

        @test Semigroups.alphabet(presentation(kb)) == [1, 2]
        @test !confluent(kb)
        run!(kb)
        @test active_rules(kb) == [
            (_kb1_word(alphabet, "000"), Int[]),
            (_kb1_word(alphabet, "111"), Int[]),
            (_kb1_word(alphabet, "1010"), _kb1_word(alphabet, "0011")),
            (_kb1_word(alphabet, "1100"), _kb1_word(alphabet, "0101")),
        ]
        @test confluent(kb)
        @test number_of_classes(kb) == POSITIVE_INFINITY
        _kb1_expect_normal_forms(
            kb,
            alphabet,
            0,
            4,
            [
                "",
                "0",
                "1",
                "00",
                "01",
                "10",
                "11",
                "001",
                "010",
                "011",
                "100",
                "101",
                "110",
                "0010",
                "0011",
                "0100",
                "0101",
                "0110",
                "1001",
                "1011",
                "1101",
            ],
        )
        nfs = _kb1_normal_forms_between(kb, length(alphabet), 0, 10)
        @test all(w -> Semigroups.reduce(kb, w) == w, nfs)
    end

    @testset "004: Example 5.1 in Sims (infinite)" begin
        alphabet = "abcd"
        p = _kb1_presentation(
            alphabet,
            [("ab", ""), ("ba", ""), ("cd", ""), ("dc", ""), ("ca", "ac")],
            empty_word = true,
        )

        kb = KnuthBendix(twosided, p)

        @test !confluent(kb)
        run!(kb)
        @test number_of_active_rules(kb) == 8
        @test confluent(kb)
        @test number_of_classes(kb) == POSITIVE_INFINITY
        _kb1_expect_normal_forms(
            kb,
            alphabet,
            0,
            4,
            [
                "",
                "a",
                "b",
                "c",
                "d",
                "aa",
                "ac",
                "ad",
                "bb",
                "bc",
                "bd",
                "cc",
                "dd",
                "aaa",
                "aac",
                "aad",
                "acc",
                "add",
                "bbb",
                "bbc",
                "bbd",
                "bcc",
                "bdd",
                "ccc",
                "ddd",
                "aaaa",
                "aaac",
                "aaad",
                "aacc",
                "aadd",
                "accc",
                "addd",
                "bbbb",
                "bbbc",
                "bbbd",
                "bbcc",
                "bbdd",
                "bccc",
                "bddd",
                "cccc",
                "dddd",
            ],
        )
        nfs = _kb1_normal_forms_between(kb, length(alphabet), 0, 6)
        @test all(w -> Semigroups.reduce(kb, w) == w, nfs)
    end

    @testset "005: Example 5.1 in Sims (infinite) x 2" begin
        alphabet = "aAbB"
        p = Presentation()
        set_contains_empty_word!(p, true)
        set_alphabet!(p, length(alphabet))
        add_inverse_rules!(p, _kb1_word(alphabet, "AaBb"))
        _kb1_add_rule!(p, alphabet, "ba", "ab")

        kb = KnuthBendix(twosided, p)

        @test !confluent(kb)
        run!(kb)
        @test number_of_active_rules(kb) == 8
        @test confluent(kb)
        @test number_of_classes(kb) == POSITIVE_INFINITY
        _kb1_expect_normal_forms(
            kb,
            alphabet,
            0,
            4,
            [
                "",
                "a",
                "A",
                "b",
                "B",
                "aa",
                "ab",
                "aB",
                "AA",
                "Ab",
                "AB",
                "bb",
                "BB",
                "aaa",
                "aab",
                "aaB",
                "abb",
                "aBB",
                "AAA",
                "AAb",
                "AAB",
                "Abb",
                "ABB",
                "bbb",
                "BBB",
                "aaaa",
                "aaab",
                "aaaB",
                "aabb",
                "aaBB",
                "abbb",
                "aBBB",
                "AAAA",
                "AAAb",
                "AAAB",
                "AAbb",
                "AABB",
                "Abbb",
                "ABBB",
                "bbbb",
                "BBBB",
            ],
        )
        nfs = _kb1_normal_forms_between(kb, length(alphabet), 0, 6)
        @test all(w -> Semigroups.reduce(kb, w) == w, nfs)
    end

    @testset "006: Example 5.3 in Sims" begin
        alphabet = "ab"
        p = _kb1_presentation(
            alphabet,
            [("aa", ""), ("bbb", ""), ("ababab", "")],
            empty_word = true,
        )

        kb = KnuthBendix(twosided, p)

        @test !confluent(kb)
        run!(kb)
        @test number_of_active_rules(kb) == 6
        @test confluent(kb)
        @test number_of_classes(kb) == 12
        @test length(normal_forms(kb)) == 12
        @test normal_forms(kb) == _kb1_words(
            alphabet,
            ["", "a", "b", "ab", "ba", "bb", "aba", "abb", "bab", "bba", "babb", "bbab"],
        )
        nfs = _kb1_normal_forms_between(kb, length(alphabet), 0, 6)
        @test all(w -> Semigroups.reduce(kb, w) == w, nfs)
    end

    @testset "007: Example 5.4 in Sims" begin
        alphabet = "Bab"
        p = _kb1_presentation(
            alphabet,
            [("aa", ""), ("bB", ""), ("bbb", ""), ("ababab", "")],
            empty_word = true,
        )

        kb = KnuthBendix(twosided, p)

        @test !confluent(kb)
        run!(kb)
        @test number_of_active_rules(kb) == 11
        @test confluent(kb)
        @test number_of_classes(kb) == 12
        nf = _kb1_normal_forms_between(kb, length(alphabet), 1, 5)
        @test length(nf) == 11
        @test nf == _kb1_words(
            alphabet,
            ["B", "a", "b", "Ba", "aB", "ab", "ba", "BaB", "Bab", "aBa", "baB"],
        )
    end

    @testset "008: Example 6.4 in Sims" begin
        alphabet = "abc"
        p = _kb1_presentation(
            alphabet,
            [
                ("aa", ""),
                ("bc", ""),
                ("bbb", ""),
                ("ababababababab", ""),
                ("abacabacabacabac", ""),
            ],
            empty_word = true,
        )

        kb = KnuthBendix(twosided, p)

        @test !confluent(kb)
        run!(kb)
        @test number_of_active_rules(kb) == 40
        @test confluent(kb)
        @test Semigroups.reduce(kb, _kb1_word(alphabet, "cc")) == _kb1_word(alphabet, "b")
        @test Semigroups.reduce(kb, _kb1_word(alphabet, "ccc")) == Int[]
        @test number_of_classes(kb) == 168
        _kb1_expect_normal_forms(
            kb,
            alphabet,
            1,
            4,
            [
                "a",
                "b",
                "c",
                "ab",
                "ac",
                "ba",
                "ca",
                "aba",
                "aca",
                "bab",
                "bac",
                "cab",
                "cac",
                "abab",
                "abac",
                "acab",
                "acac",
                "baba",
                "baca",
                "caba",
                "caca",
            ],
        )
    end

    @testset "009: random example" begin
        alphabet = "012"
        p = _kb1_presentation(alphabet, [("000", "2"), ("111", "2"), ("010101", "2")])
        add_identity_rules!(p, _kb1_word(alphabet, "2")[1])

        kb = KnuthBendix(twosided, p)

        @test !confluent(kb)
        run!(kb)
        @test number_of_active_rules(kb) == 9
        @test confluent(kb)

        wg = gilman_graph(kb)
        @test number_of_nodes(wg) == 9
        @test _kb1_number_of_edges(wg) == 13
        @test !_kb1_is_acyclic(wg)
        _kb1_expect_normal_forms(
            kb,
            alphabet,
            1,
            4,
            [
                "0",
                "1",
                "2",
                "00",
                "01",
                "10",
                "11",
                "001",
                "010",
                "011",
                "100",
                "101",
                "110",
                "0010",
                "0011",
                "0100",
                "0101",
                "0110",
                "1001",
                "1011",
                "1101",
            ],
        )
    end

    @testset "010: SL(2, 7) from Chap. 3, Prop. 1.5 in NR" begin
        alphabet = "abAB"
        p = _kb1_presentation(
            alphabet,
            [
                ("aaaaaaa", ""),
                ("bb", "ababab"),
                ("bb", "aaaabaaaabaaaabaaaab"),
                ("aA", ""),
                ("Aa", ""),
                ("bB", ""),
                ("Bb", ""),
            ],
            empty_word = true,
        )

        kb = KnuthBendix(twosided, p)

        @test !confluent(kb)
        run!(kb)
        @test number_of_active_rules(kb) == 152
        @test confluent(kb)
        @test number_of_classes(kb) == 336

        wg = gilman_graph(kb)
        @test number_of_nodes(wg) == 232
        @test _kb1_number_of_edges(wg) == 265
        @test _kb1_is_acyclic(wg)
        @test _kb1_path_count(wg, 0, 13) == 336
    end

    @testset "011: F(2, 5) - Chap. 9, Sec. 1 in NR" begin
        alphabet = "abcde"
        p = _kb1_presentation(
            alphabet,
            [("ab", "c"), ("bc", "d"), ("cd", "e"), ("de", "a"), ("ea", "b")],
        )

        kb = KnuthBendix(twosided, p)

        @test !confluent(kb)
        run!(kb)
        @test number_of_active_rules(kb) == 24
        @test confluent(kb)
        @test number_of_classes(kb) == 11

        wg = gilman_graph(kb)
        @test number_of_nodes(wg) == 8
        @test _kb1_number_of_edges(wg) == 11
        @test _kb1_is_acyclic(wg)
        @test _kb1_path_count(wg, 0, 5) == 12
    end

    @testset "012: Reinis example 1" begin
        alphabet = "abc"
        p = _kb1_presentation(alphabet, [("a", "abb"), ("b", "baa")])

        kb = KnuthBendix(twosided, p)

        @test !confluent(kb)
        run!(kb)
        @test number_of_active_rules(kb) == 4

        wg = gilman_graph(kb)
        @test number_of_nodes(wg) == 7
        @test _kb1_number_of_edges(wg) == 17
        @test !_kb1_is_acyclic(wg)
        @test _kb1_path_count(wg, 0, 9) == 13_044
    end

    @testset "013: redundant_rule (string adaptation)" begin
        alphabet = "abc"
        p = _kb1_presentation(
            alphabet,
            [("a", "abb"), ("b", "baa"), ("c", "abbabababaaababababab")],
        )

        @test redundant_rule(p, Millisecond(100)) === nothing

        _kb1_add_rule!(p, alphabet, "b", "baa")
        idx = redundant_rule(p, Millisecond(100))
        @test idx !== nothing
        @test rule_lhs(p, idx) == _kb1_word(alphabet, "b")
        @test rule_rhs(p, idx) == _kb1_word(alphabet, "baa")
    end

    @testset "014: redundant_rule (word_type)" begin
        p = Presentation()
        set_alphabet!(p, 3)
        add_rule!(p, [1], [1, 2, 2])
        add_rule!(p, [2], [2, 1, 1])
        add_rule!(p, [3], [1, 2, 2, 1, 2, 1, 2, 1, 1, 1, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1])

        @test redundant_rule(p, Millisecond(10)) === nothing

        add_rule!(p, [2], [2, 1, 1])
        idx = redundant_rule(p, Millisecond(10))
        @test idx !== nothing
        @test rule_lhs(p, idx) == [2]
        @test rule_rhs(p, idx) == [2, 1, 1]
    end

    @testset "015: constructors/init for finished" begin
        alphabet1 = "abcd"
        p1 = _kb1_presentation(
            alphabet1,
            [("ab", ""), ("ba", ""), ("cd", ""), ("dc", ""), ("ca", "ac")],
            empty_word = true,
        )

        alphabet2 = "01"
        p2 = _kb1_presentation(
            alphabet2,
            [("000", ""), ("111", ""), ("010101", "")],
            empty_word = true,
        )

        kb1 = KnuthBendix(twosided, p1)
        @test !confluent(kb1)
        @test !finished(kb1)
        run!(kb1)
        @test confluent(kb1)
        @test Semigroups.reduce(kb1, _kb1_word(alphabet1, "abababbdbcbdbabdbdb")) ==
              _kb1_word(alphabet1, "bbbbbbddd")

        init!(kb1, twosided, p2)
        @test !confluent(kb1)
        @test !finished(kb1)
        @test _kb1_same_presentation(presentation(kb1), p2)
        run!(kb1)
        @test finished(kb1)
        @test confluent(kb1)
        @test confluent_known(kb1)

        init!(kb1, twosided, p1)
        @test !confluent(kb1)
        @test !finished(kb1)
        @test _kb1_same_presentation(presentation(kb1), p1)
        run!(kb1)
        @test finished(kb1)
        @test confluent(kb1)
        @test confluent_known(kb1)
        @test Semigroups.reduce(kb1, _kb1_word(alphabet1, "abababbdbcbdbabdbdb")) ==
              _kb1_word(alphabet1, "bbbbbbddd")

        kb2 = copy(kb1)
        @test confluent(kb2)
        @test confluent_known(kb2)
        @test finished(kb2)
        @test Semigroups.reduce(kb2, _kb1_word(alphabet1, "abababbdbcbdbabdbdb")) ==
              _kb1_word(alphabet1, "bbbbbbddd")

        kb1 = copy(kb2)
        @test confluent(kb1)
        @test confluent_known(kb1)
        @test finished(kb1)
        @test Semigroups.reduce(kb1, _kb1_word(alphabet1, "abababbdbcbdbabdbdb")) ==
              _kb1_word(alphabet1, "bbbbbbddd")

        init!(kb1, twosided, p1)
        @test !confluent(kb1)
        @test !finished(kb1)
        run!(kb1)
        @test finished(kb1)
        @test confluent(kb1)
        @test confluent_known(kb1)
        @test Semigroups.reduce(kb1, _kb1_word(alphabet1, "abababbdbcbdbabdbdb")) ==
              _kb1_word(alphabet1, "bbbbbbddd")
    end

    @testset "016: constructors/init for partially run" begin
        alphabet = "abc"
        p = _kb1_presentation(
            alphabet,
            [
                ("aa", ""),
                ("bc", ""),
                ("bbb", ""),
                ("ababababababab", ""),
                ("abacabacabacabacabacabacabacabac", ""),
            ],
            empty_word = true,
        )

        kb1 = KnuthBendix(twosided, p)
        @test !confluent(kb1)
        @test !finished(kb1)
        run_for!(kb1, Millisecond(10))
        @test !confluent(kb1)
        @test !finished(kb1)

        init!(kb1, twosided, p)
        @test !confluent(kb1)
        @test !finished(kb1)
        @test _kb1_same_presentation(presentation(kb1), p)
        run_for!(kb1, Millisecond(10))
        @test !confluent(kb1)
        @test !finished(kb1)

        kb2 = copy(kb1)
        @test !confluent(kb2)
        @test !finished(kb2)
        @test _kb1_same_presentation(presentation(kb2), p)
        @test number_of_active_rules(kb1) == number_of_active_rules(kb2)
        run_for!(kb2, Millisecond(10))
        @test !confluent(kb2)
        @test !finished(kb2)

        active = number_of_active_rules(kb2)
        kb1 = copy(kb2)
        @test number_of_active_rules(kb1) == active
        @test !finished(kb1)

        init!(kb1, twosided, p)
        add_generating_pair!(kb1, _kb1_word(alphabet, "ab"), _kb1_word(alphabet, "ba"))
        @test number_of_generating_pairs(kb1) == 1
        @test generating_pairs(kb1) ==
              [(_kb1_word(alphabet, "ab"), _kb1_word(alphabet, "ba"))]

        init!(kb1, twosided, p)
        @test number_of_generating_pairs(kb1) == 0
        @test isempty(generating_pairs(kb1))

        add_generating_pair!(kb1, _kb1_word(alphabet, "ab"), _kb1_word(alphabet, "ba"))
        @test number_of_generating_pairs(kb1) == 1
        @test length(generating_pairs(kb1)) == 1

        init!(kb1)
        @test number_of_generating_pairs(kb1) == 0
        @test isempty(generating_pairs(kb1))
    end

    @testset "017: non-trivial classes" begin
        alphabet = "abc"
        p = _kb1_presentation(
            alphabet,
            [
                ("ab", "ba"),
                ("ac", "ca"),
                ("aa", "a"),
                ("ac", "a"),
                ("ca", "a"),
                ("bc", "cb"),
                ("bbb", "b"),
                ("bc", "b"),
                ("cb", "b"),
            ],
        )

        kb1 = KnuthBendix(twosided, p)
        _kb1_add_rule!(p, alphabet, "a", "b")
        kb2 = KnuthBendix(twosided, p)

        @test Semigroups.contains(kb2, _kb1_word(alphabet, "a"), _kb1_word(alphabet, "b"))
        @test Semigroups.contains(kb2, _kb1_word(alphabet, "a"), _kb1_word(alphabet, "ba"))
        @test Semigroups.contains(kb2, _kb1_word(alphabet, "a"), _kb1_word(alphabet, "bb"))
        @test Semigroups.contains(kb2, _kb1_word(alphabet, "a"), _kb1_word(alphabet, "bab"))
        @test non_trivial_classes(kb1, kb2) ==
              [_kb1_words(alphabet, ["b", "ab", "bb", "abb", "a"])]
    end

    @testset "018: non-trivial classes x 2" begin
        alphabet = "abc"
        p = _kb1_presentation(
            alphabet,
            [
                ("ab", "ba"),
                ("ac", "ca"),
                ("aa", "a"),
                ("ac", "a"),
                ("ca", "a"),
                ("bc", "cb"),
                ("bbb", "b"),
                ("bc", "b"),
                ("cb", "b"),
            ],
        )

        kb1 = KnuthBendix(twosided, p)
        @test number_of_classes(kb1) == POSITIVE_INFINITY

        _kb1_add_rule!(p, alphabet, "b", "c")
        kb2 = KnuthBendix(twosided, p)
        @test number_of_classes(kb2) == 2
        @test_throws LibsemigroupsError non_trivial_classes(kb1, kb2)
    end

    @testset "019: non-trivial classes x 3" begin
        alphabet = "abc"
        p = _kb1_presentation(
            alphabet,
            [
                ("ab", "ba"),
                ("ac", "ca"),
                ("aa", "a"),
                ("ac", "a"),
                ("ca", "a"),
                ("bc", "cb"),
                ("bbb", "b"),
                ("bc", "b"),
                ("cb", "b"),
            ],
        )

        kb1 = KnuthBendix(twosided, p)
        _kb1_add_rule!(p, alphabet, "bb", "a")
        kb2 = KnuthBendix(twosided, p)

        @test non_trivial_classes(kb1, kb2) ==
              [_kb1_words(alphabet, ["ab", "b"]), _kb1_words(alphabet, ["bb", "abb", "a"])]
    end

    @testset "020: non-trivial classes x 4" begin
        p = Presentation()
        set_alphabet!(p, 4)
        add_rule_no_checks!(p, [1, 2], [2, 1])
        add_rule_no_checks!(p, [1, 3], [3, 1])
        add_rule_no_checks!(p, [1, 1], [1])
        add_rule_no_checks!(p, [1, 3], [1])
        add_rule_no_checks!(p, [3, 1], [1])
        add_rule_no_checks!(p, [2, 3], [3, 2])
        add_rule_no_checks!(p, [2, 2, 2], [2])
        add_rule_no_checks!(p, [2, 3], [2])
        add_rule_no_checks!(p, [3, 2], [2])
        add_rule_no_checks!(p, [1, 4], [1])
        add_rule_no_checks!(p, [4, 1], [1])
        add_rule_no_checks!(p, [2, 4], [2])
        add_rule_no_checks!(p, [4, 2], [2])
        add_rule_no_checks!(p, [3, 4], [3])
        add_rule_no_checks!(p, [4, 3], [3])

        kb1 = KnuthBendix(twosided, p)
        add_rule_no_checks!(p, [1], [2])
        kb2 = KnuthBendix(twosided, p)

        @test non_trivial_classes(kb1, kb2) == [[[2], [1, 2], [2, 2], [1, 2, 2], [1]]]
    end

    @testset "021: non-trivial congruence on infinite fp semigroup" begin
        p = Presentation()
        set_alphabet!(p, 5)
        for (lhs, rhs) in [
            ([0, 1], [0]),
            ([1, 0], [0]),
            ([0, 2], [0]),
            ([2, 0], [0]),
            ([0, 3], [0]),
            ([3, 0], [0]),
            ([0, 0], [0]),
            ([1, 1], [0]),
            ([2, 2], [0]),
            ([3, 3], [0]),
            ([1, 2], [0]),
            ([2, 1], [0]),
            ([1, 3], [0]),
            ([3, 1], [0]),
            ([2, 3], [0]),
            ([3, 2], [0]),
            ([4, 0], [0]),
            ([4, 1], [1]),
            ([4, 2], [2]),
            ([4, 3], [3]),
            ([0, 4], [0]),
            ([1, 4], [1]),
            ([2, 4], [2]),
            ([3, 4], [3]),
        ]
            _kb1_add_cpp_rule!(p, lhs, rhs)
        end

        kb1 = KnuthBendix(twosided, p)
        rows1 = [[1, 2, 3, 4, 5], [], [], [], [], [nothing, nothing, nothing, nothing, 5]]
        @test number_of_classes(kb1) == POSITIVE_INFINITY
        @test _kb1_paths_take(gilman_graph(kb1), 1000) == _kb1_paths_take_rows(rows1, 1000)

        _kb1_add_cpp_rule!(p, [1], [2])
        kb2 = KnuthBendix(twosided, p)
        rows2 = [[1, 2, nothing, 3, 4], [], [], [], [nothing, nothing, nothing, nothing, 4]]

        @test number_of_classes(kb1) == POSITIVE_INFINITY
        @test _kb1_paths_take(gilman_graph(kb2), 1000) == _kb1_paths_take_rows(rows2, 1000)
        @test Semigroups.contains(kb2, [2], [3])

        ntc = non_trivial_classes(kb1, kb2)
        @test length(ntc) == 1
        @test length(ntc[1]) == 2
        @test ntc == [[[3], [2]]]
    end

    @testset "022: non-trivial congruence on infinite fp semigroup x 2" begin
        p = Presentation()
        set_alphabet!(p, 5)
        for (lhs, rhs) in [
            ([0, 1], [0]),
            ([1, 0], [0]),
            ([0, 2], [0]),
            ([2, 0], [0]),
            ([0, 3], [0]),
            ([3, 0], [0]),
            ([0, 0], [0]),
            ([1, 1], [0]),
            ([2, 2], [0]),
            ([3, 3], [0]),
            ([1, 2], [0]),
            ([2, 1], [0]),
            ([1, 3], [0]),
            ([3, 1], [0]),
            ([2, 3], [0]),
            ([3, 2], [0]),
            ([4, 0], [0]),
            ([4, 1], [2]),
            ([4, 2], [3]),
            ([4, 3], [1]),
            ([0, 4], [0]),
            ([1, 4], [2]),
            ([2, 4], [3]),
            ([3, 4], [1]),
        ]
            _kb1_add_cpp_rule!(p, lhs, rhs)
        end

        kb1 = KnuthBendix(twosided, p)
        _kb1_add_cpp_rule!(p, [2], [3])
        kb2 = KnuthBendix(twosided, p)

        ntc = non_trivial_classes(kb1, kb2)
        @test length(ntc) == 1
        @test length(ntc[1]) == 3
        @test ntc == [[[3], [4], [2]]]
    end

    @testset "023: trivial congruence on finite fp semigroup" begin
        p = Presentation()
        set_alphabet!(p, 2)
        for (lhs, rhs) in [
            ([0, 0, 1], [0, 0]),
            ([0, 0, 0, 0], [0, 0]),
            ([0, 1, 1, 0], [0, 0]),
            ([0, 1, 1, 1], [0, 0, 0]),
            ([1, 1, 1, 0], [1, 1, 0]),
            ([1, 1, 1, 1], [1, 1, 1]),
            ([0, 1, 0, 0, 0], [0, 1, 0, 1]),
            ([0, 1, 0, 1, 0], [0, 1, 0, 0]),
            ([0, 1, 0, 1, 1], [0, 1, 0, 1]),
        ]
            _kb1_add_cpp_rule!(p, lhs, rhs)
        end

        kb1 = KnuthBendix(twosided, p)
        kb2 = KnuthBendix(twosided, p)

        @test !contains_empty_word(p)
        @test number_of_classes(kb1) == 27
        @test number_of_classes(kb2) == 27
        @test isempty(non_trivial_classes(kb1, kb2))
    end

    @testset "024: universal congruence on finite fp semigroup" begin
        p = Presentation()
        set_alphabet!(p, 2)
        for (lhs, rhs) in [
            ([0, 0, 1], [0, 0]),
            ([0, 0, 0, 0], [0, 0]),
            ([0, 1, 1, 0], [0, 0]),
            ([0, 1, 1, 1], [0, 0, 0]),
            ([1, 1, 1, 0], [1, 1, 0]),
            ([1, 1, 1, 1], [1, 1, 1]),
            ([0, 1, 0, 0, 0], [0, 1, 0, 1]),
            ([0, 1, 0, 1, 0], [0, 1, 0, 0]),
            ([0, 1, 0, 1, 1], [0, 1, 0, 1]),
        ]
            _kb1_add_cpp_rule!(p, lhs, rhs)
        end

        kb1 = KnuthBendix(twosided, p)

        _kb1_add_cpp_rule!(p, [0], [1])
        _kb1_add_cpp_rule!(p, [0, 0], [0])
        kb2 = KnuthBendix(twosided, p)

        @test number_of_classes(kb2) == 1
        ntc = non_trivial_classes(kb1, kb2)
        @test length(ntc) == 1
        @test length(ntc[1]) == 27

        expected = _kb1_cword.([
            [0],
            [1],
            [0, 0],
            [0, 1],
            [1, 0],
            [1, 1],
            [0, 0, 0],
            [1, 0, 0],
            [0, 1, 0],
            [1, 0, 1],
            [0, 1, 1],
            [1, 1, 0],
            [1, 1, 1],
            [1, 0, 0, 0],
            [0, 1, 0, 0],
            [1, 1, 0, 0],
            [1, 0, 1, 0],
            [0, 1, 0, 1],
            [1, 1, 0, 1],
            [1, 0, 1, 1],
            [1, 1, 0, 0, 0],
            [1, 0, 1, 0, 0],
            [1, 1, 0, 1, 0],
            [1, 0, 1, 0, 1],
            [1, 1, 0, 1, 1],
            [1, 1, 0, 1, 0, 0],
            [1, 1, 0, 1, 0, 1],
        ])
        @test sort(repr.(ntc[1])) == sort(repr.(expected))
    end

    @testset "025: finite fp semigroup, size 16" begin
        p = Presentation()
        set_alphabet!(p, 11)
        for (lhs, rhs) in [
            ([2], [1]),
            ([4], [3]),
            ([5], [0]),
            ([6], [3]),
            ([7], [1]),
            ([8], [3]),
            ([9], [3]),
            ([10], [0]),
            ([0, 2], [0, 1]),
            ([0, 4], [0, 3]),
            ([0, 5], [0, 0]),
            ([0, 6], [0, 3]),
            ([0, 7], [0, 1]),
            ([0, 8], [0, 3]),
            ([0, 9], [0, 3]),
            ([0, 10], [0, 0]),
            ([1, 1], [1]),
            ([1, 2], [1]),
            ([1, 4], [1, 3]),
            ([1, 5], [1, 0]),
            ([1, 6], [1, 3]),
            ([1, 7], [1]),
            ([1, 8], [1, 3]),
            ([1, 9], [1, 3]),
            ([1, 10], [1, 0]),
            ([3, 1], [3]),
            ([3, 2], [3]),
            ([3, 3], [3]),
            ([3, 4], [3]),
            ([3, 5], [3, 0]),
            ([3, 6], [3]),
            ([3, 7], [3]),
            ([3, 8], [3]),
            ([3, 9], [3]),
            ([3, 10], [3, 0]),
            ([0, 0, 0], [0]),
            ([0, 0, 1], [1]),
            ([0, 0, 3], [3]),
            ([0, 1, 3], [1, 3]),
            ([1, 0, 0], [1]),
            ([1, 0, 3], [0, 3]),
            ([3, 0, 0], [3]),
            ([0, 1, 0, 1], [1, 0, 1]),
            ([0, 3, 0, 3], [3, 0, 3]),
            ([1, 0, 1, 0], [1, 0, 1]),
            ([1, 3, 0, 1], [1, 0, 1]),
            ([1, 3, 0, 3], [3, 0, 3]),
            ([3, 0, 1, 0], [3, 0, 1]),
            ([3, 0, 3, 0], [3, 0, 3]),
        ]
            _kb1_add_cpp_rule!(p, lhs, rhs)
        end

        kb1 = KnuthBendix(twosided, p)
        @test number_of_nodes(gilman_graph(kb1)) == 16

        rows1 = [
            [
                3,
                1,
                nothing,
                2,
                nothing,
                nothing,
                nothing,
                nothing,
                nothing,
                nothing,
                nothing,
            ],
            [6, nothing, nothing, 12],
            [7, nothing],
            [4, 5, nothing, 9],
            [],
            [8],
            [nothing, 11],
            [nothing, 14, nothing, 15],
            [],
            [10],
            [nothing, 14],
            [],
            [13],
            [nothing],
            [],
            [],
        ]
        @test _kb1_paths_take(gilman_graph(kb1), 16) == _kb1_paths_take_rows(rows1, 16)

        _kb1_add_cpp_rule!(p, [1], [3])
        kb2 = KnuthBendix(twosided, p)
        rows2 = [
            [
                2,
                1,
                nothing,
                nothing,
                nothing,
                nothing,
                nothing,
                nothing,
                nothing,
                nothing,
                nothing,
            ],
            [],
            [3],
            [],
        ]
        @test _kb1_paths_take(gilman_graph(kb2), 3) == _kb1_paths_take_rows(rows2, 3)

        ntc = non_trivial_classes(kb1, kb2)
        expected = _kb1_cword.([
            [1],
            [3],
            [0, 1],
            [0, 3],
            [1, 0],
            [3, 0],
            [1, 3],
            [0, 1, 0],
            [0, 3, 0],
            [1, 0, 1],
            [3, 0, 1],
            [3, 0, 3],
            [1, 3, 0],
            [0, 3, 0, 1],
        ])
        @test sort(repr.(ntc[1])) == sort(repr.(expected))
    end

    @testset "026: non_trivial_classes exceptions" begin
        p = Presentation()
        set_alphabet!(p, 1)
        kbp = KnuthBendix(twosided, p)

        q = Presentation()
        set_alphabet!(q, 2)
        kbq = KnuthBendix(twosided, q)
        @test_throws LibsemigroupsError non_trivial_classes(kbp, kbq)
        @test number_of_inactive_rules(kbq) == 0

        add_rule_no_checks!(p, [1, 1, 1, 1], [1, 1])
        init!(kbp, twosided, p)

        q = Presentation()
        set_alphabet!(q, 1)
        add_rule_no_checks!(q, [1, 1], [1])
        kbq = KnuthBendix(twosided, q)
        @test_throws LibsemigroupsError non_trivial_classes(kbq, kbp)
    end

    @testset "checked free-word inputs" begin
        for alphabet in ("a", [1])
            strings = alphabet isa String
            valid = strings ? "a" : [1]
            longer = strings ? "aa" : [1, 1]
            invalid = strings ? "z" : [2]
            epsilon = strings ? "" : Int[]
            p = Presentation(alphabet)
            kb = KnuthBendix(twosided, p)

            @test Semigroups.contains(kb, valid, valid)
            @test !Semigroups.contains(kb, valid, longer)
            for bad in (invalid, epsilon)
                @test_throws LibsemigroupsError Semigroups.contains(kb, bad, valid)
                @test_throws LibsemigroupsError Semigroups.contains(kb, valid, bad)
                @test_throws LibsemigroupsError Semigroups.contains(kb, bad, bad)
            end

            set_contains_empty_word!(p, true)
            monoid = KnuthBendix(twosided, p)
            @test Semigroups.contains(monoid, epsilon, epsilon)
            @test !Semigroups.contains(monoid, epsilon, valid)
            @test !Semigroups.contains(monoid, valid, epsilon)
        end
    end
end
