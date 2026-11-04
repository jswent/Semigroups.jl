# Copyright (c) 2026, James W. Swent
#
# Distributed under the terms of the GPL license version 3.
#
# The full license is in the file LICENSE, distributed with this software.

"""
setup.jl - Library location and build logic for Semigroups.jl

This module handles locating the compiled C++ wrapper library,
either from a pre-built location or by building it from source.
Uses libsemigroups_jll for the pre-built libsemigroups headers and library.
"""

module Setup

using CxxWrap
using libsemigroups_jll
import FileWatching: Pidfile
import Libdl
import Pkg
import Preferences
import TOML

const WRAPPER_ID =
    Base.PkgId(Base.UUID("49785210-2e0e-5fa7-bc86-ac158b29c4ea"), "libsemigroups_julia_jll")
const library_source = Ref("unknown")
const library_version = Ref("unknown")

deps_dir() = joinpath(dirname(@__DIR__), "deps")
src_dir() = joinpath(deps_dir(), "src")
build_dir() = joinpath(deps_dir(), "build-$VERSION")
library_name() = "libsemigroups_julia.$(Libdl.dlext)"
library_path() = joinpath(build_dir(), library_name())
local_state_path() = joinpath(build_dir(), "libsemigroups_julia.toml")
canonical_path(path) = ispath(path) ? realpath(path) : abspath(path)
source_tree_hash() = bytes2hex(Pkg.GitTools.tree_hash(src_dir()))

function jll_package_dir()
    path = Base.locate_package(WRAPPER_ID)
    path === nothing &&
        error("libsemigroups_julia_jll is not installed; run Pkg.instantiate().")
    return dirname(dirname(path))
end

function jll_version()
    return library_version[]
end

# Importing a JLL eagerly dlopens its products. Inspect its metadata instead,
# so an automatic local build never loads the published wrapper as a side effect.
function jll_artifact()
    root = jll_package_dir()
    artifacts_toml = joinpath(root, "Artifacts.toml")
    Base.include_dependency(artifacts_toml)
    Base.include_dependency(joinpath(root, "Project.toml"))
    override = joinpath(root, "override")
    if isdir(override)
        return (directory = override, overridden = true)
    end
    hash = Pkg.Artifacts.artifact_hash(
        "libsemigroups_julia",
        artifacts_toml;
        pkg_uuid = WRAPPER_ID.uuid,
    )
    hash === nothing &&
        error("No libsemigroups_julia artifact supports this Julia/platform combination.")
    Pkg.Artifacts.ensure_artifact_installed(
        "libsemigroups_julia",
        artifacts_toml;
        pkg_uuid = WRAPPER_ID.uuid,
    )
    directory = Pkg.Artifacts.artifact_path(hash)
    original = Pkg.Artifacts.artifact_path(hash; honor_overrides = false)
    return (directory = directory, overridden = directory != original)
end

function jll_tree_hashes(directory)
    path = joinpath(directory, "lib", "libsemigroups_julia.treehash")
    isfile(path) || return String[]
    Base.include_dependency(path)
    return split(read(path, String))
end

function package_is_from_registry()
    pkginfo = get(Pkg.dependencies(), Base.PkgId(parentmodule(Setup)).uuid, nothing)
    return pkginfo !== nothing && pkginfo.is_tracking_registry
end

function track_sources()
    for (directory, _, files) in walkdir(src_dir())
        # Track directories as well, to invalidate caches when files are added
        # or removed. This also works with Julia 1.10's mtime-based tracking.
        Base.include_dependency(directory)
        for file in files
            Base.include_dependency(joinpath(directory, file))
        end
    end
end

function loaded_wrappers()
    return unique(
        canonical_path(path) for path in Libdl.dllist() if
        occursin(r"^libsemigroups_julia\.(?:so|dylib|dll)(?:\.|$)", basename(path))
    )
end

function check_loaded_wrapper(path)
    selected = canonical_path(path)
    others = filter(!=(selected), loaded_wrappers())
    isempty(others) || error(
        "A different libsemigroups_julia wrapper is already loaded: " *
        join(others, ", ") *
        ". Selected wrapper: $selected. " *
        "Restart Julia before changing wrappers; load Semigroups without first " *
        "importing libsemigroups_julia_jll when using a local build.",
    )
    return path
end

function load_jll_library(path)
    check_loaded_wrapper(path)
    # Once selected, let the JLL initialize its product and participate in
    # Julia's dependency/preference invalidation. Never import it for a local build.
    @eval import libsemigroups_julia_jll
    actual, version = Base.invokelatest() do
        jll = libsemigroups_julia_jll
        return jll.libsemigroups_julia, string(Base.pkgversion(jll))
    end
    canonical_path(actual) == canonical_path(path) || error(
        "The JLL resolved a different libsemigroups_julia library; restart Julia and regenerate precompiled bindings.",
    )
    check_loaded_wrapper(actual)
    library_version[] = version
    return actual
end

function build_configuration()
    return Dict(
        "julia_version" => string(VERSION),
        "julia_commit" => Base.GIT_VERSION_INFO.commit,
        "julia_executable" => realpath(joinpath(Sys.BINDIR, Base.julia_exename())),
        "platform" => Sys.MACHINE,
        "cxxwrap_prefix" => realpath(CxxWrap.prefix_path()),
        "cxxwrap_version" => string(CxxWrap.libcxxwrapversion()),
        "core_prefix" => realpath(libsemigroups_jll.artifact_dir),
        "core_library" => realpath(libsemigroups_jll.libsemigroups),
        "core_mtime" => mtime(libsemigroups_jll.libsemigroups),
    )
end

function local_state()
    try
        return TOML.parsefile(local_state_path())
    catch exception
        exception isa InterruptException && rethrow()
        return Dict{String,Any}()
    end
end

function local_library_is_current(lib_path, src_hash, configuration)
    state = local_state()
    return isfile(lib_path) &&
           get(state, "source_hash", nothing) == src_hash &&
           get(state, "configuration", nothing) == configuration
end

function build_library(src_hash = source_tree_hash())
    configuration = build_configuration()
    lib_path = library_path()
    check_loaded_wrapper(lib_path)
    Pidfile.mkpidlock(build_dir() * ".pid"; stale_age = 300) do
        local_library_is_current(lib_path, src_hash, configuration) && return lib_path
        isempty(loaded_wrappers()) || error(
            "The loaded libsemigroups_julia wrapper needs rebuilding. Restart Julia first.",
        )
        # CMake caches Julia/header locations. Start clean if an ABI input
        # changed, but retain incremental compilation for source-only edits.
        if get(local_state(), "configuration", nothing) != configuration
            rm(build_dir(); force = true, recursive = true)
        end
        mkpath(build_dir())
        @info "Building libsemigroups_julia library..."
        jlcxx_dir = CxxWrap.prefix_path()
        core = libsemigroups_jll.artifact_dir
        cmake_args = [
            "-DCMAKE_BUILD_TYPE=Release",
            "-DJulia_EXECUTABLE=$(joinpath(Sys.BINDIR, Base.julia_exename()))",
            "-DJlCxx_DIR=$(joinpath(jlcxx_dir, "lib", "cmake", "JlCxx"))",
            "-DLIBSEMIGROUPS_INCLUDE_DIR=$(joinpath(core, "include"))",
            "-DLIBSEMIGROUPS_LIBRARY_DIR=$(joinpath(core, "lib"))",
        ]
        Sys.isapple() && push!(cmake_args, "-DCMAKE_OSX_DEPLOYMENT_TARGET=11.0")
        run(`cmake $cmake_args -S $(src_dir()) -B $(build_dir())`)
        run(`cmake --build $(build_dir()) --config Release`)
        isfile(lib_path) || error("Build did not produce $lib_path")
        open(local_state_path(), "w") do io
            TOML.print(
                io,
                Dict("source_hash" => src_hash, "configuration" => configuration),
            )
        end
        @info "Build complete: $lib_path"
        return lib_path
    end
end

function locate_library()
    track_sources()
    preference =
        Preferences.load_preference(WRAPPER_ID.uuid, "libsemigroups_julia_path", nothing)
    if preference !== nothing
        preference isa String || error("libsemigroups_julia_path must be a library path.")
        path = abspath(preference)
        isfile(path) ||
            error("The overridden libsemigroups_julia library does not exist: $path")
        path = load_jll_library(path)
        library_source[] = "override"
        return path
    end

    artifact = jll_artifact()
    src_hash = source_tree_hash()
    if artifact.overridden ||
       package_is_from_registry() ||
       src_hash in jll_tree_hashes(artifact.directory)
        path = joinpath(artifact.directory, "lib", library_name())
        isfile(path) || error("The libsemigroups_julia artifact does not contain $path")
        path = load_jll_library(path)
        library_source[] = artifact.overridden ? "override" : "JLL"
        return path
    end

    path = library_path()
    check_loaded_wrapper(path)
    configuration = build_configuration()
    if !local_library_is_current(path, src_hash, configuration)
        build_library(src_hash)
    end
    library_source[] = "dev/local"
    return path
end

end # module Setup
