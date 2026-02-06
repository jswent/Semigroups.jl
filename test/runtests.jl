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
    include("test_constants.jl")
    include("test_errors.jl")
    include("test_transf.jl")
end
