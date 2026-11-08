# Copyright (c) 2026, James W. Swent
#
# Distributed under the terms of the GPL license version 3.

"""
test_todd_coxeter.jl - Tests for ToddCoxeter

Ports a focused subset of [quick] cases from
libsemigroups/tests/test-todd-coxeter.cpp, plus binding-surface and
high-level integration tests.
"""

using Test
using Semigroups
using Dates

# Build a 1-based Julia word from 0-based libsemigroups indices.
# `_tc_word(0, 0, 1)` -> `[1, 1, 2]`. Long prefix avoids shadowing in shared
# test scope.
_tc_word(xs::Integer...) = [Int(x) + 1 for x in xs]

@testset "ToddCoxeter binding surface" begin
    @test isdefined(Semigroups, :ToddCoxeter)

    # Constructors (4 forms)
    @test hasmethod(ToddCoxeter, Tuple{congruence_kind,Presentation})
    @test hasmethod(ToddCoxeter, Tuple{congruence_kind,ToddCoxeter})
    @test hasmethod(ToddCoxeter, Tuple{congruence_kind,WordGraph})
    @test hasmethod(ToddCoxeter, Tuple{ToddCoxeter})

    # init! overloads (4 forms)
    @test hasmethod(init!, Tuple{ToddCoxeter})
    @test hasmethod(init!, Tuple{ToddCoxeter,congruence_kind,Presentation})
    @test hasmethod(init!, Tuple{ToddCoxeter,congruence_kind,ToddCoxeter})
    @test hasmethod(init!, Tuple{ToddCoxeter,congruence_kind,WordGraph})

    # Settings (8 getter / 8 setter pairs)
    @test hasmethod(strategy, Tuple{ToddCoxeter})
    @test hasmethod(strategy!, Tuple{ToddCoxeter,typeof(strategy_hlt)})
    @test hasmethod(lookahead_extent, Tuple{ToddCoxeter})
    @test hasmethod(lookahead_extent!, Tuple{ToddCoxeter,typeof(lookahead_extent_full)})
    @test hasmethod(lookahead_style, Tuple{ToddCoxeter})
    @test hasmethod(lookahead_style!, Tuple{ToddCoxeter,typeof(lookahead_style_hlt)})
    @test hasmethod(save, Tuple{ToddCoxeter})
    @test hasmethod(save!, Tuple{ToddCoxeter,Bool})
    @test hasmethod(use_relations_in_extra, Tuple{ToddCoxeter})
    @test hasmethod(use_relations_in_extra!, Tuple{ToddCoxeter,Bool})
    @test hasmethod(lower_bound, Tuple{ToddCoxeter})
    @test hasmethod(lower_bound!, Tuple{ToddCoxeter,Integer})
    @test hasmethod(def_version, Tuple{ToddCoxeter})
    @test hasmethod(def_version!, Tuple{ToddCoxeter,typeof(def_version_one)})
    @test hasmethod(def_policy, Tuple{ToddCoxeter})
    @test hasmethod(def_policy!, Tuple{ToddCoxeter,typeof(def_policy_purge_all)})

    # Standardize and word-graph access
    @test hasmethod(standardize!, Tuple{ToddCoxeter,Order})
    @test hasmethod(is_standardized, Tuple{ToddCoxeter})
    @test hasmethod(is_standardized, Tuple{ToddCoxeter,Order})
    @test hasmethod(current_word_graph, Tuple{ToddCoxeter})
    @test hasmethod(word_graph, Tuple{ToddCoxeter})

    # Word <-> class index
    @test hasmethod(index_of, Tuple{ToddCoxeter,AbstractVector{<:Integer}})
    @test hasmethod(current_index_of, Tuple{ToddCoxeter,AbstractVector{<:Integer}})
    @test hasmethod(word_of, Tuple{ToddCoxeter,Integer})
    @test hasmethod(current_word_of, Tuple{ToddCoxeter,Integer})
    @test hasmethod(
        throw_if_letter_not_in_alphabet,
        Tuple{ToddCoxeter,AbstractVector{<:Integer}},
    )

    # Query methods
    @test hasmethod(number_of_classes, Tuple{ToddCoxeter})
    @test hasmethod(kind, Tuple{ToddCoxeter})
    @test hasmethod(number_of_generating_pairs, Tuple{ToddCoxeter})
    @test hasmethod(generating_pairs, Tuple{ToddCoxeter})
    @test hasmethod(presentation, Tuple{ToddCoxeter})

    # Free functions
    @test hasmethod(is_non_trivial, Tuple{ToddCoxeter})
    @test hasmethod(tc_redundant_rule, Tuple{Presentation,TimePeriod})

    # Base.* overloads
    @test hasmethod(Base.length, Tuple{ToddCoxeter})
    @test hasmethod(Base.show, Tuple{IO,ToddCoxeter})
    @test hasmethod(Base.copy, Tuple{ToddCoxeter})

    # Inherited from CongruenceCommon (wrapped in src/cong-common.jl).
    # `contains` and `reduce` shadow Base, so they stay module-qualified.
    @test hasmethod(
        add_generating_pair!,
        Tuple{CongruenceCommon,AbstractVector{<:Integer},AbstractVector{<:Integer}},
    )
    @test hasmethod(
        currently_contains,
        Tuple{CongruenceCommon,AbstractVector{<:Integer},AbstractVector{<:Integer}},
    )
    @test hasmethod(
        Semigroups.contains,
        Tuple{CongruenceCommon,AbstractVector{<:Integer},AbstractVector{<:Integer}},
    )
    @test hasmethod(Semigroups.reduce, Tuple{CongruenceCommon,AbstractVector{<:Integer}})
    @test hasmethod(reduce_no_run, Tuple{CongruenceCommon,AbstractVector{<:Integer}})
    @test hasmethod(normal_forms, Tuple{CongruenceCommon})
    @test hasmethod(non_trivial_classes, Tuple{CongruenceCommon,CongruenceCommon})
end

# ============================================================================
# correctness tests inspired by test-todd-coxeter.cpp
# ============================================================================

@testset "TC000 - small 2-sided congruence (27 classes)" begin
    # Port of libsemigroups TC000 (test-todd-coxeter.cpp:294-341).
    # 2-generator semigroup, rules: 000 = 0, 1111 = 1, 0101 = 00.
    p = Presentation()
    set_alphabet!(p, 2)
    add_rule_no_checks!(p, _tc_word(0, 0, 0), _tc_word(0))
    add_rule_no_checks!(p, _tc_word(1, 1, 1, 1), _tc_word(1))
    add_rule_no_checks!(p, _tc_word(0, 1, 0, 1), _tc_word(0, 0))

    tc = ToddCoxeter(twosided, p)
    @test number_of_classes(tc) == 27
    @test finished(tc)

    standardize!(tc, ORDER_SHORTLEX)
    @test length(normal_forms(tc)) == 27
end

@testset "TC001 - small 2-sided congruence (5 classes)" begin
    # Port of libsemigroups TC001 (test-todd-coxeter.cpp:343-441).
    # 2-generator semigroup, rules: 000 = 0, 0 = 11.
    p = Presentation()
    set_alphabet!(p, 2)
    add_rule_no_checks!(p, _tc_word(0, 0, 0), _tc_word(0))
    add_rule_no_checks!(p, _tc_word(0), _tc_word(1, 1))

    tc = ToddCoxeter(twosided, p)
    run!(tc)
    @test number_of_classes(tc) == 5
    @test finished(tc)

    # Index-of: 001 == 00001 (1-based: [1,1,2] == [1,1,1,1,2])
    @test index_of(tc, _tc_word(0, 0, 1)) == index_of(tc, _tc_word(0, 0, 0, 0, 1))
    @test index_of(tc, _tc_word(0, 1, 1, 0, 0, 1)) == index_of(tc, _tc_word(0, 0, 0, 0, 1))
    @test index_of(tc, _tc_word(0, 0, 0)) != index_of(tc, _tc_word(1))

    # Standardize for shortlex (TC001 lines 371-374)
    standardize!(tc, ORDER_SHORTLEX)
    @test word_of(tc, 1) == _tc_word(0)        # C++ index 0
    @test word_of(tc, 2) == _tc_word(1)        # C++ index 1
    @test word_of(tc, 3) == _tc_word(0, 0)     # C++ index 2

    # Standardize for lex (TC001 lines 375-391)
    standardize!(tc, ORDER_LEX)
    @test is_standardized(tc, ORDER_LEX)
    @test is_standardized(tc)
    @test !is_standardized(tc, ORDER_SHORTLEX)

    @test word_of(tc, 1) == _tc_word(0)           # 0
    @test word_of(tc, 2) == _tc_word(0, 0)        # 00
    @test word_of(tc, 3) == _tc_word(0, 0, 1)     # 001
    @test word_of(tc, 4) == _tc_word(0, 0, 1, 0)  # 0010
    @test word_of(tc, 5) == _tc_word(1)           # 1

    # word_of/index_of round-trip (1-based)
    for i = 1:5
        @test index_of(tc, word_of(tc, i)) == i
    end

    standardize!(tc, ORDER_SHORTLEX)
    @test is_standardized(tc, ORDER_SHORTLEX)
    @test normal_forms(tc) ==
          [_tc_word(0), _tc_word(1), _tc_word(0, 0), _tc_word(0, 1), _tc_word(0, 0, 1)]
end

@testset "TC - quotient construction (kind, ToddCoxeter)" begin
    # Port of libsemigroups TC025 (test-todd-coxeter.cpp:1447-1468), reduced.
    p = Presentation()
    set_alphabet!(p, 2)
    add_rule_no_checks!(p, _tc_word(0, 0, 0), _tc_word(0))
    add_rule_no_checks!(p, _tc_word(0), _tc_word(1, 1))

    tc1 = ToddCoxeter(twosided, p)
    @test number_of_classes(tc1) == 5

    tc2 = ToddCoxeter(onesided, tc1)
    add_generating_pair!(tc2, _tc_word(0), _tc_word(0, 0))
    @test number_of_classes(tc2) == 3
end

@testset "TC024 - constructor from WordGraph" begin
    # Port of libsemigroups TC024 (test-todd-coxeter.cpp:1435-1445).
    # Upstream only requires the constructor not to throw; mirror that and add
    # a few cheap state observations. The 1-node, 2-out-degree WordGraph has
    # all-UNDEFINED targets.
    wg = WordGraph(1, 2)
    @test out_degree(wg) == 2
    @test number_of_nodes(wg) == 1

    tc = ToddCoxeter(twosided, wg)
    @test tc isa ToddCoxeter
    @test kind(tc) == twosided
    @test (finished(tc); started(tc); true)
end

# OpenAI Codex assisted with the ASCII graph initialization regression.
@testset "TC - string graph initialization preserves ASCII capacity" begin
    p = Presentation("a")
    add_rule!(p, "aa", "a")
    tc = ToddCoxeter(twosided, p)
    add_generating_pair!(tc, "aaa", "a")
    strategy!(tc, strategy_felsch)

    @test_throws ArgumentError init!(tc, twosided, WordGraph(2, 129))
    @test presentation(tc) == p
    @test generating_pairs(tc) == [("aaa", "a")]
    @test strategy(tc) == strategy_felsch

    @test init!(tc, twosided, WordGraph(2, 128)) === tc
    @test sort(collect(alphabet(presentation(tc)))) == Char.(0:127)
    @test out_degree(current_word_graph(tc)) == 128

    numeric = ToddCoxeter()
    @test init!(numeric, twosided, WordGraph(2, 129)) === numeric
    @test length(alphabet(presentation(numeric))) == 129
end

@testset "TC settings round-trip (8 pairs)" begin
    p = Presentation()
    set_alphabet!(p, 2)
    add_rule_no_checks!(p, _tc_word(0, 0, 0), _tc_word(0))
    add_rule_no_checks!(p, _tc_word(0), _tc_word(1, 1))
    tc = ToddCoxeter(twosided, p)

    strategy!(tc, strategy_felsch)
    @test strategy(tc) == strategy_felsch

    lookahead_extent!(tc, lookahead_extent_full)
    @test lookahead_extent(tc) == lookahead_extent_full

    lookahead_style!(tc, lookahead_style_felsch)
    @test lookahead_style(tc) == lookahead_style_felsch

    save!(tc, true)
    @test save(tc) == true

    use_relations_in_extra!(tc, false)
    @test use_relations_in_extra(tc) == false

    # Default is UNDEFINED (no bound). Setting then clearing round-trips.
    @test lower_bound(tc) === UNDEFINED
    lower_bound!(tc, 5)
    @test lower_bound(tc) == 5
    lower_bound!(tc, UNDEFINED)
    @test lower_bound(tc) === UNDEFINED

    def_version!(tc, def_version_two)
    @test def_version(tc) == def_version_two

    def_policy!(tc, def_policy_purge_all)
    @test def_policy(tc) == def_policy_purge_all
end

@testset "TC - current_word_graph after run!" begin
    # After run!, current_word_graph may include inactive allocation slots,
    # so it has at least number_of_classes(tc) + 1 nodes (the +1 accounts for
    # the inactive node 0 for presentations without the empty word).
    # word_graph(tc) standardizes and prunes, giving exactly that count.
    p = Presentation()
    set_alphabet!(p, 2)
    add_rule_no_checks!(p, _tc_word(0, 0, 0), _tc_word(0))
    add_rule_no_checks!(p, _tc_word(0), _tc_word(1, 1))

    tc = ToddCoxeter(twosided, p)
    run!(tc)

    cwg = current_word_graph(tc)
    @test number_of_nodes(cwg) >= number_of_classes(tc) + 1

    swg = word_graph(tc)
    @test number_of_nodes(swg) == number_of_classes(tc) + 1
end

@testset "TC - is_non_trivial on free monogenic" begin
    # Port of libsemigroups TC031 fragment (test-todd-coxeter.cpp:1730-1739).
    # Free monogenic semigroup is non-trivial.
    p = Presentation()
    set_alphabet!(p, 1)
    tc = ToddCoxeter(twosided, p)
    @test is_non_trivial(tc) == tril_TRUE
end

@testset "TC - tc_redundant_rule" begin
    p = Presentation()
    set_alphabet!(p, 2)
    add_rule_no_checks!(p, _tc_word(0, 0, 0), _tc_word(0))
    add_rule_no_checks!(p, _tc_word(0), _tc_word(1, 1))
    @test tc_redundant_rule(p, Millisecond(50)) === nothing

    # Add a duplicate rule -> trivially redundant.
    add_rule_no_checks!(p, _tc_word(0, 0, 0), _tc_word(0))
    idx = tc_redundant_rule(p, Millisecond(100))
    @test idx isa Integer
    @test 1 <= idx <= number_of_rules(p)
end

@testset "TC - throw_if_letter_not_in_alphabet" begin
    p = Presentation()
    set_alphabet!(p, 2)
    add_rule_no_checks!(p, _tc_word(0, 0, 0), _tc_word(0))
    add_rule_no_checks!(p, _tc_word(0), _tc_word(1, 1))
    tc = ToddCoxeter(twosided, p)

    @test throw_if_letter_not_in_alphabet(tc, _tc_word(0, 1, 0)) === nothing
    @test_throws LibsemigroupsError throw_if_letter_not_in_alphabet(tc, _tc_word(0, 5))
end

@testset "TC - cong-common helpers (reduce, contains, currently_contains, normal_forms)" begin
    p = Presentation()
    set_alphabet!(p, 2)
    add_rule_no_checks!(p, _tc_word(0, 0, 0), _tc_word(0))
    add_rule_no_checks!(p, _tc_word(0), _tc_word(1, 1))
    tc = ToddCoxeter(twosided, p)

    # contains triggers a run and agrees with index_of equality.
    @test Semigroups.contains(tc, _tc_word(0, 0, 1), _tc_word(0, 0, 0, 0, 1))
    @test currently_contains(tc, _tc_word(0, 0, 1), _tc_word(0, 0, 0, 0, 1)) == tril_TRUE

    r = Semigroups.reduce(tc, _tc_word(0, 0, 0, 0, 1))
    @test r isa Vector{Int}
    @test Semigroups.contains(tc, r, _tc_word(0, 0, 0, 0, 1))

    @test length(normal_forms(tc)) == number_of_classes(tc)
end

@testset "TC - non_trivial_classes(tc1, tc2) for a quotient pair" begin
    p = Presentation()
    set_alphabet!(p, 2)
    add_rule_no_checks!(p, _tc_word(0, 0, 0), _tc_word(0))
    add_rule_no_checks!(p, _tc_word(0), _tc_word(1, 1))

    tc1 = ToddCoxeter(twosided, p)
    @test number_of_classes(tc1) == 5

    # tc2 collapses 0 ~ 1 -> strictly fewer classes than tc1.
    tc2 = ToddCoxeter(twosided, p)
    add_generating_pair!(tc2, _tc_word(0), _tc_word(1))
    @test number_of_classes(tc2) < number_of_classes(tc1)

    classes = non_trivial_classes(tc1, tc2)
    @test classes isa AbstractVector
end

@testset "ToddCoxeter high-level Julia API" begin
    p = Presentation()
    set_alphabet!(p, 2)
    add_rule_no_checks!(p, _tc_word(0, 0, 0), _tc_word(0))
    add_rule_no_checks!(p, _tc_word(0), _tc_word(1, 1))

    tc = ToddCoxeter(twosided, p)
    @test length(tc) == number_of_classes(tc)
    @test !isempty(sprint(show, tc))

    # copy: independent objects.
    tc2 = copy(tc)
    @test length(tc2) == length(tc)
    strategy!(tc2, strategy_felsch)
    @test strategy(tc2) == strategy_felsch

    # 1-based round-trip for index_of / word_of.
    standardize!(tc, ORDER_SHORTLEX)
    for i = 1:Int(number_of_classes(tc))
        @test index_of(tc, word_of(tc, i)) == i
    end

    # Setter chaining: each setter returns tc, so calls compose left-to-right.
    save!(strategy!(tc, strategy_felsch), false)
    @test strategy(tc) == strategy_felsch
    @test save(tc) == false

    # standardize! returns a Bool.
    fresh = ToddCoxeter(twosided, p)
    run!(fresh)
    @test standardize!(fresh, ORDER_SHORTLEX) isa Bool
end

# ============================================================================
# TODO - port full test-todd-coxeter.cpp test cases
# ============================================================================
