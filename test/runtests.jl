# Copyright (c) 2026, James W. Swent
#
# Distributed under the terms of the GPL license version 3.
#
# The full license is in the file LICENSE, distributed with this software.

"""
runtests.jl - Test runner for Semigroups.jl
"""

using Test
using Semigroups

@testset "Semigroups.jl" begin
    include("test_loading.jl")
    include("test_bmat8.jl")
    include("test_constants.jl")
    include("test_errors.jl")
    include("test_order.jl")
    include("test_runner.jl")
    include("test_transf.jl")
    include("test_word_graph.jl")
    include("test_paths.jl")
    include("test_presentation.jl")
    include("test_presentation_examples.jl")
    include("test_word_range.jl")
    include("test_froidure_pin_transf.jl")
    include("test_knuth_bendix_1.jl")
    include("test_knuth_bendix_6.jl")
    include("test_todd_coxeter.jl")
    include("test_kambites.jl")
    include("test_to.jl")
end
