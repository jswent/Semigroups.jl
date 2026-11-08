# Copyright (c) 2026, James W. Swent
#
# Distributed under the terms of the GPL license version 3.
#
# The full license is in the file LICENSE, distributed with this software.

"""
test_runner.jl - Tests for Runner base class bindings

Runner is abstract, so we cannot instantiate it directly. These tests verify
that types, constants, and method definitions are correctly bound. Behavioral
tests are exercised via concrete derived classes (e.g. FroidurePin) once they
are available.
"""

using Dates: TimePeriod

@testset "Runner type aliases" begin
    @test isabstracttype(Runner)
    @test CongruenceCommon <: Runner
    @test KnuthBendix <: CongruenceCommon
    @test ToddCoxeter <: CongruenceCommon
    @test Kambites <: CongruenceCommon
    @test RunnerState === Semigroups.LibSemigroups.state
end

@testset "RunnerState constants" begin
    # All state constants are accessible and have the right type
    states = [
        STATE_NEVER_RUN,
        STATE_RUNNING_TO_FINISH,
        STATE_RUNNING_FOR,
        STATE_RUNNING_UNTIL,
        STATE_TIMED_OUT,
        STATE_STOPPED_BY_PREDICATE,
        STATE_NOT_RUNNING,
        STATE_DEAD,
    ]

    for s in states
        @test s isa RunnerState
    end

    # All state constants are distinct
    for i in eachindex(states), j in eachindex(states)
        if i != j
            @test states[i] != states[j]
        end
    end
end

@testset "Runner method definitions" begin
    # Verify that each wrapper function is defined with the correct
    # signature dispatching on Runner
    @test hasmethod(run!, Tuple{Runner})
    @test hasmethod(run_for!, Tuple{Runner,TimePeriod})
    @test hasmethod(run_until!, Tuple{Function,Runner})
    @test hasmethod(run_until!, Tuple{Runner,Function})
    @test hasmethod(init!, Tuple{Runner})
    @test hasmethod(kill!, Tuple{Runner})

    @test hasmethod(finished, Tuple{Runner})
    @test hasmethod(success, Tuple{Runner})
    @test hasmethod(started, Tuple{Runner})
    @test hasmethod(running, Tuple{Runner})
    @test hasmethod(timed_out, Tuple{Runner})
    @test hasmethod(stopped, Tuple{Runner})
    @test hasmethod(dead, Tuple{Runner})
    @test hasmethod(stopped_by_predicate, Tuple{Runner})
    @test hasmethod(running_for, Tuple{Runner})
    @test hasmethod(running_for_how_long, Tuple{Runner})
    @test hasmethod(running_until, Tuple{Runner})
    @test hasmethod(current_state, Tuple{Runner})

    @test hasmethod(report_why_we_stopped, Tuple{Runner})
    @test hasmethod(string_why_we_stopped, Tuple{Runner})
end
