# Copyright (c) 2026, James W. Swent
#
# Distributed under the terms of the GPL license version 3.
#
# The full license is in the file LICENSE, distributed with this software.

# Run separately from runtests.jl so local C++ development can still use a
# rebuilt wrapper while this check always exercises the published binaries.
using Test
using Libdl
using libsemigroups_jll
using libsemigroups_julia_jll

module JLLBindings
using CxxWrap
import libsemigroups_julia_jll

@wrapmodule(() -> libsemigroups_julia_jll.libsemigroups_julia, :define_julia_module)

function __init__()
    @initcxx
end
end

@testset "Registered JLL binaries" begin
    core_version = Base.pkgversion(libsemigroups_jll)
    wrapper_version = Base.pkgversion(libsemigroups_julia_jll)
    built_against = VersionNumber(JLLBindings.libsemigroups_version())
    core_path = realpath(libsemigroups_jll.libsemigroups)
    wrapper_path = realpath(libsemigroups_julia_jll.libsemigroups_julia)
    loaded_paths = Set(realpath(path) for path in Libdl.dllist() if isfile(path))

    @info "Registered JLL binaries" core_version wrapper_version built_against core_path wrapper_path

    @test core_path in loaded_paths
    @test wrapper_path in loaded_paths
    @test Set(
        path for path in loaded_paths if occursin(r"^(lib)?semigroups[.-]", basename(path))
    ) == Set([core_path])
    @test built_against ==
          VersionNumber(core_version.major, core_version.minor, core_version.patch)
end
