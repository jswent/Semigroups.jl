# Copyright (c) 2026, James W. Swent
#
# Distributed under the terms of the GPL license version 3.
#
# The full license is in the file LICENSE, distributed with this software.

"""
build.jl - Build script for semigroups_julia C++ library

This script builds the C++ wrapper library during package installation.
"""

using CxxWrap

# Get the source and build directories
const src_dir = joinpath(@__DIR__, "src")
const build_dir = joinpath(@__DIR__, "build")

# Create build directory
mkpath(build_dir)

# Get JlCxx directory
const jlcxx_dir = CxxWrap.prefix_path()

# Get Julia paths to work around FindJulia.cmake issues
julia_bindir = dirname(Sys.BINDIR)
julia_includedir = joinpath(julia_bindir, "include", "julia")
julia_libdir = joinpath(julia_bindir, "lib")

println("Building semigroups_julia library...")
println("Source directory: $src_dir")
println("Build directory: $build_dir")
println("JlCxx directory: $jlcxx_dir")
println("Julia include dir: $julia_includedir")
println("Julia lib dir: $julia_libdir")

# CMake arguments
cmake_args = [
    "-DCMAKE_BUILD_TYPE=Release",
    "-DJlCxx_DIR=$(joinpath(jlcxx_dir, "lib", "cmake", "JlCxx"))",
    "-DJulia_EXECUTABLE=$(joinpath(Sys.BINDIR, "julia"))",
    "-DJulia_INCLUDE_DIRS=$julia_includedir",
    "-DJulia_LIBRARY_DIR=$julia_libdir",
]

# Add macOS-specific flags if needed
if Sys.isapple()
    push!(cmake_args, "-DCMAKE_OSX_DEPLOYMENT_TARGET=11.0")
end

# Run CMake configure
cd(build_dir) do
    run(`cmake $(cmake_args) $(src_dir)`)
    run(`cmake --build . --config Release`)
end

println("Build complete!")
