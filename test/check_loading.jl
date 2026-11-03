# Copyright (c) 2026, James W. Swent
#
# Distributed under the terms of the GPL license version 3.
#
# The full license is in the file LICENSE, distributed with this software.

# Run in its own process: native libraries cannot safely be switched in-place.
using Test, Semigroups, Libdl, TOML

const root = dirname(@__DIR__)
const wrapper_uuid = string(Semigroups.Setup.WRAPPER_ID.uuid)
const selected = realpath(Semigroups.libsemigroups_julia())
const artifact = Semigroups.Setup.jll_artifact().directory
const published = joinpath(artifact, "lib", Semigroups.Setup.library_name())

function fixture_project(directory)
    package = TOML.parsefile(joinpath(root, "Project.toml"))
    project = Dict("deps" => merge(package["deps"], Dict("Semigroups" => package["uuid"])))
    open(joinpath(directory, "Project.toml"), "w") do io
        TOML.print(io, project)
    end
    manifest = TOML.parsefile(joinpath(dirname(Base.active_project()), "Manifest.toml"))
    entries = get!(manifest["deps"], "Semigroups", [Dict{String,Any}()])
    entry = only(entries)
    empty!(entry)
    merge!(
        entry,
        Dict(
            "uuid" => package["uuid"],
            "version" => package["version"],
            "path" => root,
            "deps" => collect(keys(package["deps"])),
        ),
    )
    open(joinpath(directory, "Manifest.toml"), "w") do io
        TOML.print(io, manifest)
    end
end

function library_preference(directory, path)
    open(joinpath(directory, "LocalPreferences.toml"), "w") do io
        TOML.print(
            io,
            Dict("libsemigroups_julia_jll" => Dict("libsemigroups_julia_path" => path)),
        )
    end
end

function run_child(
    project,
    code;
    compiled_modules = "yes",
    depot = nothing,
    recompile = false,
)
    if recompile
        code = "Base.compilecache(Base.identify_package(\"Semigroups\"));\n" * code
    end
    cmd = `$(Base.julia_cmd()) --startup-file=no --compiled-modules=$compiled_modules --project=$project -e $code`
    if depot !== nothing
        separator = Sys.iswindows() ? ';' : ':'
        cmd = addenv(cmd, "JULIA_DEPOT_PATH" => join([depot; DEPOT_PATH], separator))
    end
    mktemp() do _, io
        process = run(pipeline(cmd; stdout = io, stderr = io); wait = false)
        status = timedwait(() -> process_exited(process), 300)
        status == :timed_out && kill(process, Base.SIGKILL)
        wait(process)
        seekstart(io)
        output = read(io, String)
        success(process) || print(output)
        @test status != :timed_out
        @test success(process)
    end
end

function check_selected(path)
    return """
        using Semigroups, Libdl, Test
        @test realpath(Semigroups.libsemigroups_julia()) == $(repr(realpath(path)))
        @test Semigroups.Setup.loaded_wrappers() == [$(repr(realpath(path)))]
        if Semigroups._libsemigroups_julia_source() == "dev/local"
            @test !haskey(Base.loaded_modules, Semigroups.Setup.WRAPPER_ID)
        end
        @test length(FroidurePin(Transf([2, 1]))) == 2
        sprint(Semigroups.versioninfo)
        @test Semigroups.Setup.loaded_wrappers() == [$(repr(realpath(path)))]
        """
end

@testset "Fresh-process wrapper loading" begin
    mktempdir() do directory
        fixture_project(directory)
        # Exercise normal loading twice, including reuse of precompiled code.
        run_child(directory, check_selected(selected))
        run_child(directory, check_selected(selected))

        if Semigroups._libsemigroups_julia_source() == "dev/local"
            @testset "Published wrapper already loaded" begin
                run_child(
                    directory,
                    """
   using libsemigroups_julia_jll, Libdl, Test
   failure = try
       @eval using Semigroups
       nothing
   catch error
       error
   end
   @test failure !== nothing
   @test occursin("different libsemigroups_julia wrapper is already loaded", sprint(showerror, failure))
   loaded = unique(realpath(p) for p in Libdl.dllist() if basename(p) == $(repr(Semigroups.Setup.library_name())))
   @test loaded == [$(repr(realpath(published)))]
   """,
                )
            end
        end

        @testset "Published library preference" begin
            library_preference(directory, published)
            run_child(directory, check_selected(published); recompile = true)
            run_child(directory, check_selected(published))
        end

        @testset "Local library preference and existing-library guard" begin
            local_lib = joinpath(directory, Semigroups.Setup.library_name())
            cp(selected, local_lib)
            library_preference(directory, local_lib)
            run_child(directory, check_selected(local_lib); recompile = true)
            run_child(directory, check_selected(local_lib))
            run_child(
                directory,
                """
using CxxWrap, libsemigroups_jll, Libdl, Test
Libdl.dlopen($(repr(published)))
failure = try
    @eval using Semigroups
    nothing
catch error
    error
end
@test failure !== nothing
@test occursin("different libsemigroups_julia wrapper is already loaded", sprint(showerror, failure))
""",
            )
        end

        @testset "Artifact override" begin
            rm(joinpath(directory, "LocalPreferences.toml"))
            prefix = joinpath(directory, "override")
            mkpath(joinpath(prefix, "lib"))
            override_lib = joinpath(prefix, "lib", Semigroups.Setup.library_name())
            cp(selected, override_lib)
            depot = joinpath(directory, "depot")
            mkpath(joinpath(depot, "artifacts"))
            open(joinpath(depot, "artifacts", "Overrides.toml"), "w") do io
                TOML.print(io, Dict(wrapper_uuid => Dict("libsemigroups_julia" => prefix)))
            end
            # Artifact overrides require regenerating native bindings; do not
            # reuse a cache generated against a different library.
            run_child(
                directory,
                check_selected(override_lib);
                compiled_modules = "no",
                depot,
            )
        end
    end
end
