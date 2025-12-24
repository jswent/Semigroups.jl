# LibSemigroups.jl - CxxWrap module definition for libsemigroups bindings
#
# This module loads the compiled C++ wrapper library and exposes the
# wrapped types and functions to Julia.

module LibSemigroups

using CxxWrap

import ..Semigroups: _libsemigroups_julia_path

# Load the C++ module - this creates all the wrapped types and functions
# The library path is computed during precompilation by setup.jl
@wrapmodule(() -> _libsemigroups_julia_path, :define_julia_module)

function __init__()
    @initcxx
end

end # module LibSemigroups
