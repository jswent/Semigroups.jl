# Copyright (c) 2026, James W. Swent
#
# Distributed under the terms of the GPL license version 3.
#
# The full license is in the file LICENSE, distributed with this software.

"""
    LibSemigroups

CxxWrap module definition for libsemigroups bindings

This module loads the compiled C++ wrapper library and exposes the
wrapped types and functions to Julia.
"""

module LibSemigroups

using CxxWrap

import ..Semigroups: libsemigroups_julia, _libsemigroups_julia, Setup

# Load the C++ module - this creates all the wrapped types and functions
# The library is selected without importing the wrapper JLL.
@wrapmodule(libsemigroups_julia, :define_julia_module)

function __init__()
    # Submodule initialization precedes Semigroups.__init__. Resolve the path
    # here, before CxxWrap registers any runtime pointers.
    path = Setup.locate_library()
    if Setup.canonical_path(path) != Setup.canonical_path(_libsemigroups_julia[])
        error(
            "The selected libsemigroups_julia wrapper changed since precompilation. " *
            "Restart Julia and run Base.compilecache(Base.identify_package(\"Semigroups\")) " *
            "before loading Semigroups.",
        )
    end
    _libsemigroups_julia[] = path
    @initcxx
end

end # module LibSemigroups
