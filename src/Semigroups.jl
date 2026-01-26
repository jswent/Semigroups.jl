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
include("libsemigroups/transf.jl")

# Import error handling utilities
using .Errors: @wrap_libsemigroups_call

# High-level element types
include("elements/transf.jl")

# Module initialization
function __init__()
    # Initialize the CxxWrap module
    LibSemigroups.__init__()
end

# Exports
export UNDEFINED, POSITIVE_INFINITY, NEGATIVE_INFINITY, LIMIT_MAX
export tril, tril_FALSE, tril_TRUE, tril_unknown, tril_to_bool
export is_undefined, is_positive_infinity, is_negative_infinity, is_limit_max

# Transformation types and functions
export Transf, PPerm, Perm
export degree, rank, images, image_set, domain_set
export left_one, right_one

end # module Semigroups
