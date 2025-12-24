module Semigroups

using CxxWrap
using AbstractAlgebra

# Setup and library location
include("setup.jl")

# Get the library path - this will build if necessary during precompilation
const _libsemigroups_julia_path = Setup.locate_library()

# Low-level CxxWrap bindings
include("LibSemigroups.jl")

# Re-export the low-level module for advanced users
using .LibSemigroups

# Julia-side wrapper files
include("libsemigroups/constants.jl")
include("libsemigroups/errors.jl")

# Module initialization
function __init__()
    # Initialize the CxxWrap module
    LibSemigroups.__init__()
end

# Exports
export UNDEFINED, POSITIVE_INFINITY, NEGATIVE_INFINITY, LIMIT_MAX
export tril, tril_FALSE, tril_TRUE, tril_unknown, tril_to_bool
export is_undefined, is_positive_infinity, is_negative_infinity, is_limit_max
export SemigroupsError, have_error, check_error!, clear_errors!, get_and_clear_errors

end # module Semigroups
