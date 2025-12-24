# setup.jl - Library location and build logic for Semigroups.jl
#
# This module handles locating the compiled C++ wrapper library,
# either from a pre-built location or by building it from source.

module Setup

using CxxWrap

# Get the path to the deps directory
function deps_dir()
    return joinpath(dirname(@__DIR__), "deps")
end

# Get the path to the source directory
function src_dir()
    return joinpath(deps_dir(), "src")
end

# Get the path to the build directory
function build_dir()
    return joinpath(deps_dir(), "build")
end

# Get the expected library path
function library_path()
    if Sys.iswindows()
        return joinpath(build_dir(), "libsemigroups_julia.dll")
    elseif Sys.isapple()
        return joinpath(build_dir(), "libsemigroups_julia.dylib")
    else
        return joinpath(build_dir(), "libsemigroups_julia.so")
    end
end

# Build the C++ library from source
function build_library()
    @info "Building libsemigroups_julia library..."

    # Create build directory
    mkpath(build_dir())

    # Get JlCxx (CxxWrap C++ library) directory
    jlcxx_dir = CxxWrap.prefix_path()

    # Configure with CMake
    cmake_args = [
        "-DCMAKE_BUILD_TYPE=Release",
        "-DJlCxx_DIR=$(joinpath(jlcxx_dir, "lib", "cmake", "JlCxx"))",
    ]

    # Add macOS-specific flags if needed
    if Sys.isapple()
        push!(cmake_args, "-DCMAKE_OSX_DEPLOYMENT_TARGET=10.15")
    end

    # Run CMake configure
    cd(build_dir()) do
        run(`cmake $(cmake_args) $(src_dir())`)
        run(`cmake --build . --config Release`)
    end

    @info "Build complete: $(library_path())"
    return library_path()
end

# Locate the library, building if necessary
function locate_library()
    lib_path = library_path()

    if !isfile(lib_path)
        @info "Library not found at $lib_path, building from source..."
        build_library()
    end

    if !isfile(lib_path)
        error("Failed to locate or build libsemigroups_julia library at $lib_path")
    end

    return lib_path
end

end # module Setup
