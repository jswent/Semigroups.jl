# Copyright (c) 2026, James W. Swent
# Distributed under the terms of the GPL license version 3.
# Prepared with OpenAI Codex for representation and ownership regressions.

using Test
using Semigroups
using Semigroups: to

function _string_semilattice(; monoid = false)
    p = Presentation("ba")
    set_contains_empty_word!(p, monoid)
    add_rule!(p, "bb", "b")
    add_rule!(p, "aa", "a")
    add_rule!(p, "ab", "ba")
    return p
end

@testset "ASCII words through congruence algorithms" begin
    ReportGuard(false)
    for Algorithm in (KnuthBendix, ToddCoxeter, Congruence)
        @testset "$Algorithm" begin
            p = _string_semilattice()
            c = Algorithm(twosided, p)
            @test c isa CongruenceCommon{String}
            @test c isa Runner
            @test alphabet(presentation(c)) == "ba"
            @test Semigroups.contains(c, "abab", "ba")
            @test !Semigroups.contains(c, "a", "b")
            @test number_of_classes(c) == 3
            @test Semigroups.reduce(c, SubString("xabab", 2)) == "ba"
            @test reduce_no_run(c, "baba") == "ba"
            @test_throws ArgumentError Semigroups.reduce(c, "α")
            @test_throws ArgumentError Semigroups.reduce(c, [1, 2])
            @test_throws LibsemigroupsError Semigroups.reduce(c, "z")
            @test_throws LibsemigroupsError Semigroups.reduce(c, "")
            @test presentation(copy(c)) == presentation(c)
            @test presentation(deepcopy(c)) == presentation(c)

            classes = Semigroups.partition(c, ["a", "aa", "b", "bb", "ab", "ba"])
            @test classes isa Vector{Vector{String}}
            @test Set(Set(cls) for cls in classes) ==
                  Set([Set(["a", "aa"]), Set(["b", "bb"]), Set(["ab", "ba"])])
            @test Semigroups.partition(c, String[]) isa Vector{Vector{String}}
            @test isempty(Semigroups.partition(c, String[]))
            @test_throws ArgumentError Semigroups.partition(c, ["a", "α"])

            q = to(Presentation{Vector{Int}}, p)
            integer_c = Algorithm(twosided, q)
            encode = ToWord(alphabet(p))
            @test number_of_classes(integer_c) == 3
            @test encode(Semigroups.reduce(c, "abab")) ==
                  Semigroups.reduce(integer_c, encode("abab"))
            @test_throws ArgumentError init!(c, twosided, q)
            @test alphabet(presentation(c)) == "ba"

            monoid = Algorithm(twosided, _string_semilattice(monoid = true))
            @test number_of_classes(monoid) == 4
            @test Semigroups.reduce(monoid, "") == ""
        end
    end
end

@testset "String representatives, copies, and graph snapshots" begin
    for Algorithm in (KnuthBendix, ToddCoxeter)
        c = Algorithm(twosided, _string_semilattice())
        forms = normal_forms(c)
        @test forms == ["b", "a", "ba"]
        @test forms isa Vector{String}
        saved = presentation(c)
        clear_rules!(saved)
        @test number_of_rules(presentation(c)) == 3
        init!(c)
        @test forms == ["b", "a", "ba"]
    end

    tc = ToddCoxeter(twosided, _string_semilattice())
    for i = 1:3
        w = word_of(tc, i)
        @test w isa String
        @test index_of(tc, w) == i
        @test current_word_of(tc, i) == w
        @test current_index_of(tc, w) == i
    end
    graph = word_graph(tc)
    node_count = number_of_nodes(graph)
    init!(tc)
    GC.gc()
    @test number_of_nodes(graph) == node_count
    @test all(
        w -> w isa String,
        Iterators.map(ToString("ba"), paths(graph; source = 1, max = 2)),
    )

    p = Presentation([10, 20])
    add_rule!(p, [10, 10], [10])
    add_rule!(p, [20], [10])
    tc = ToddCoxeter(twosided, p)
    @test normal_forms(tc) == [[10]]
    @test word_of(tc, 1) == [10]
end

@testset "NUL is a generator, not a terminator" begin
    p = Presentation("a\0")
    add_rule!(p, "aa", "a")
    add_rule!(p, "\0", "a")
    for Algorithm in (KnuthBendix, ToddCoxeter, Congruence)
        c = Algorithm(twosided, p)
        @test Semigroups.reduce(c, "\0a\0") == "a"
        @test Semigroups.contains(c, "a\0", "aa")
        @test alphabet(presentation(c)) == "a\0"
    end
end

@testset "Kambites string specialization" begin
    p = Presentation("abcdefg")
    add_rule!(p, "abcd", "aaaeaa")
    add_rule!(p, "ef", "dg")
    k = Kambites(twosided, p)
    @test small_overlap_class(k) >= 4
    @test Semigroups.contains(k, "abcd", "aaaeaa")
    @test Semigroups.contains(k, "aaaaaef", "aaaaadg")
    @test Semigroups.reduce(k, "ef") == "dg"
    @test generating_pairs(k) isa Vector{Tuple{String,String}}
    @test normal_forms(k, 0) == String[]
    @test normal_forms(k, 0) isa Vector{String}
    @test normal_forms(k, 8) isa Vector{String}
    @test_throws ArgumentError normal_forms(k)
    @test_throws ArgumentError non_trivial_classes(k, copy(k))
    @test_throws ArgumentError Semigroups.reduce(k, "é")
end

@testset "Representation-preserving conversions" begin
    p = _string_semilattice()
    q = to(Presentation{Vector{Int}}, p)
    r = to(Presentation{String}, q; alphabet = "ba")
    @test r == p
    @test r !== p
    @test alphabet(to(Presentation{String}, q)) != "ba"
    kb = KnuthBendix(twosided, p)
    tc = to(ToddCoxeter, twosided, kb)
    @test tc isa ToddCoxeter{String}
    @test alphabet(presentation(tc)) == "ba"
    @test to(KnuthBendix, twosided, tc) isa KnuthBendix{String}
    @test to(Presentation, kb) isa Presentation{String}
    @test to(Presentation, tc) isa Presentation{String}
    @test to(Presentation, Congruence(twosided, p)) isa Presentation{String}
    @test to(Presentation, Kambites(twosided, Presentation("ab"))) isa Presentation{String}
    @test to(ToddCoxeter{Vector{Int}}, twosided, kb) isa ToddCoxeter{Vector{Int}}
    ip = to(InversePresentation, Presentation("ab"))
    @test ip isa InversePresentation{String}
    @test to(InversePresentation{Vector{Int}}, ip) isa InversePresentation{Vector{Int}}
    @test_throws ArgumentError to(InversePresentation, Presentation("abcdefghijklmnop"))

    for monoid in (false, true)
        p = _string_semilattice(; monoid)
        original_tc = ToddCoxeter(twosided, p)
        converted_kb = to(KnuthBendix, twosided, original_tc)
        @test number_of_classes(converted_kb) == (monoid ? 4 : 3)
        # Native by-value moves used to invalidate rewrite-rule iterators here.
        @test number_of_classes(copy(converted_kb)) == (monoid ? 4 : 3)
        converted_tc = to(ToddCoxeter, twosided, converted_kb)
        @test alphabet(presentation(converted_tc)) == "ba"
        @test contains_empty_word(presentation(converted_tc)) == monoid
        @test number_of_classes(converted_tc) == (monoid ? 4 : 3)

        empty_p = Presentation("")
        set_contains_empty_word!(empty_p, monoid)
        empty_tc = to(ToddCoxeter, twosided, KnuthBendix(twosided, empty_p))
        @test number_of_classes(empty_tc) == (monoid ? 1 : 0)
        @test alphabet(presentation(empty_tc)) == ""
        @test contains_empty_word(presentation(empty_tc)) == monoid
    end

    fp = FroidurePin(Transf([2, 1, 3]), Transf([2, 3, 1]))
    @test !started(fp)
    @test_throws ArgumentError to(Presentation{String}, fp; alphabet = "αβ")
    @test_throws ArgumentError to(Presentation{String}, fp; alphabet = "aa")
    @test_throws ArgumentError to(Presentation{String}, fp; alphabet = "a")
    @test !started(fp)
    @test alphabet(to(Presentation{String}, fp; alphabet = "xy")) == "xy"
end

@testset "One-sided ASCII generator capacity" begin
    letters = String(UInt8.(0:127))
    for Algorithm in (KnuthBendix, Congruence)
        c = Algorithm(onesided, Presentation(letters))
        @test_throws ArgumentError add_generating_pair!(c, "a", "b")
        @test number_of_generating_pairs(c) == 0
        @test alphabet(presentation(c)) == letters
    end
end

@testset "Congruence copies own independent computations" begin
    for W in (String, Vector{Int}), duplicate in (copy, deepcopy, Congruence)
        p = to(Presentation{W}, _string_semilattice())
        u, v = W === String ? ("b", "a") : ([1], [2])
        original = Congruence(twosided, p)
        @test currently_contains(original, u, v) == tril_unknown
        @test !started(original)
        copied = duplicate(original)
        @test !started(copied)
        add_generating_pair!(copied, u, v)
        @test Semigroups.contains(copied, u, v)
        @test !Semigroups.contains(original, u, v)
        @test number_of_generating_pairs(original) == 0
        @test number_of_generating_pairs(copied) == 1
        @test number_of_classes(original) == 3
        @test number_of_classes(copied) == 1
    end

    for W in (String, Vector{Int})
        graph = word_graph(ToddCoxeter(twosided, _string_semilattice()))
        u, v = W === String ? ("a", "b") : ([1], [2])
        original = to(Congruence{W}, twosided, graph)
        copied = copy(original)
        add_generating_pair!(copied, u, v)
        @test number_of_classes(copied) == 1
        @test number_of_classes(original) == 3
        @test number_of_generating_pairs(original) == 0
        @test !Semigroups.contains(original, u, v)
        @test number_of_classes(deepcopy(original)) == 3
        @test number_of_classes(deepcopy(copied)) == 1
        @test generating_pairs(deepcopy(copied)) == [(u, v)]

        # Reinitialization discards the original graph definition.
        p = W === String ? Presentation("a") : Presentation([1])
        a, aa = W === String ? ("a", "aa") : ([1], [1, 1])
        add_rule!(p, aa, a)
        init!(original, twosided, p)
        @test number_of_classes(deepcopy(original)) == 1
        init!(original)
        reset_copy = deepcopy(original)
        init!(reset_copy, twosided, p)
        @test number_of_classes(reset_copy) == 1

        fp = FroidurePin(Transf([2, 1, 3]), Transf([2, 3, 1]))
        from_fp = to(Congruence{W}, twosided, fp, right_cayley_graph(fp))
        @test number_of_classes(from_fp) == 6
        @test number_of_classes(deepcopy(from_fp)) == 6
    end
end
