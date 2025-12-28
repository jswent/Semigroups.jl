using Test
using Semigroups

@testset "Semigroups.jl" begin
    include("test_constants.jl")
    include("test_errors.jl")
    include("test_transf.jl")
end
