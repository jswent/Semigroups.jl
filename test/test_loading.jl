# Copyright (c) 2026, James W. Swent
#
# Distributed under the terms of the GPL license version 3.
#
# The full license is in the file LICENSE, distributed with this software.

using Libdl

@testset "Wrapper selection" begin
    selected = realpath(Semigroups.libsemigroups_julia())
    @test Semigroups.Setup.loaded_wrappers() == [selected]
    # Diagnostics must not import the wrapper JLL as a side effect.
    output = sprint(Semigroups.versioninfo)
    @test occursin("libsemigroups_julia", output)
    @test Semigroups.Setup.loaded_wrappers() == [selected]

    if Semigroups._libsemigroups_julia_source() == "dev/local"
        @testset "Native build cache" begin
            setup = Semigroups.Setup
            hash = setup.source_tree_hash()
            configuration = setup.build_configuration()
            @test setup.local_library_is_current(selected, hash, configuration)
            @test !setup.local_library_is_current(selected, hash * "changed", configuration)
            for key in ("julia_commit", "cxxwrap_prefix", "core_prefix")
                changed = copy(configuration)
                changed[key] *= "changed"
                @test !setup.local_library_is_current(selected, hash, changed)
            end
            timestamp = mtime(selected)
            @test setup.locate_library() == selected
            @test mtime(selected) == timestamp
            @test_throws ErrorException setup.build_library(hash * "changed")
            @test mtime(selected) == timestamp
        end
    end
end
