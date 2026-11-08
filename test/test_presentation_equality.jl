# Copyright (c) 2026, James W. Swent
# Distributed under the terms of the GPL license version 3.
# OpenAI Codex assisted with the independent equality-contract review.

using Test
using Semigroups

@testset "Presentation equality distinguishes semigroups from monoids" begin
    for W in (String, Vector{Int})
        p = W === String ? Presentation("a") : Presentation([1])
        a, aa = W === String ? ("a", "aa") : ([1], [1, 1])
        add_rule!(p, aa, a)
        q = copy(p)
        set_contains_empty_word!(q, true)
        @test number_of_classes(ToddCoxeter(twosided, p)) == 1
        @test number_of_classes(ToddCoxeter(twosided, q)) == 2

        for make in (identity, InversePresentation)
            s, m = make(p), make(q)
            if s isa InversePresentation
                set_inverses!(s, a)
                set_inverses!(m, a)
            end
            @test s != m
            @test m != s
            @test !isequal(s, m)
            @test length(Set([s, m])) == 2
            values = Dict(s => :semigroup, m => :monoid)
            @test values[copy(s)] === :semigroup
            @test values[copy(m)] === :monoid
            @test hash(copy(s)) == hash(s)
            @test hash(copy(m)) == hash(m)
        end
    end
end
