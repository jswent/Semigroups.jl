# Copyright (c) 2026, James W. Swent
#
# Distributed under the terms of the GPL license version 3.
#
# The full license is in the file LICENSE, distributed with this software.

module Semigroups

using CxxWrap
using AbstractAlgebra

# ============================================================================
# Debug mode
# ============================================================================

const _debug_mode = Ref(false)

"""
    enable_debug(val::Bool=true)

Enable or disable debug mode for libsemigroups tracing.

When debug mode is enabled, the full C++ stack trace from libsemigroups/jlcxx
is shown instead of only the high-level Julia translation.

# Example
```julia
Semigroups.enable_debug()       # enable debug mode
Semigroups.enable_debug(false)  # disable debug mode
```
"""
enable_debug(val::Bool = true) = (_debug_mode[] = val)

"""
    is_debug() -> Bool

Check if debug mode is enabled for libsemigroups error handling.
"""
is_debug() = _debug_mode[]

# ============================================================================
# Package setup
# ============================================================================

# Setup and library location
include("setup.jl")

# Get the library path - this will build if necessary during precompilation
const _libsemigroups_julia_path = Setup.locate_library()

# Low-level CxxWrap bindings
include("LibSemigroups.jl")

# Re-export the low-level module for advanced users
using .LibSemigroups

# Import error handling utilities
include("libsemigroups/errors.jl")
using .Errors: LibsemigroupsError, @wrap_libsemigroups_call

# Julia-side wrapper files
include("libsemigroups/constants.jl")
include("libsemigroups/transf.jl")

# High-level element types
include("elements/transf.jl")

# Module initialization
function __init__()
    # Initialize the CxxWrap module
    LibSemigroups.__init__()
end

# ============================================================================
# Exports
# ============================================================================

export enable_debug, is_debug, LibsemigroupsError
export UNDEFINED, POSITIVE_INFINITY, NEGATIVE_INFINITY, LIMIT_MAX
export tril, tril_FALSE, tril_TRUE, tril_unknown, tril_to_bool
export is_undefined, is_positive_infinity, is_negative_infinity, is_limit_max

# Transformation types and functions
export Transf, PPerm, Perm
export degree, rank, images, image_set, domain_set
export increase_degree_by!, swap!
export left_one, right_one

end # module Semigroups
