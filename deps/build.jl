# build.jl - Build script for semigroups_julia C++ library
#
# This script builds the C++ wrapper library during package installation.

using CxxWrap

# Get the source and build directories
const src_dir = joinpath(@__DIR__, "src")
const build_dir = joinpath(@__DIR__, "build")

# Create build directory
mkpath(build_dir)

# Get JlCxx directory
const jlcxx_dir = CxxWrap.prefix_path()

println("Building semigroups_julia library...")
println("Source directory: $src_dir")
println("Build directory: $build_dir")
println("JlCxx directory: $jlcxx_dir")

# CMake arguments
cmake_args = [
    "-DCMAKE_BUILD_TYPE=Release",
    "-DJlCxx_DIR=$(joinpath(jlcxx_dir, "lib", "cmake", "JlCxx"))",
]

# Add macOS-specific flags if needed
if Sys.isapple()
    push!(cmake_args, "-DCMAKE_OSX_DEPLOYMENT_TARGET=10.15")
end

# Run CMake configure
cd(build_dir) do
    run(`cmake $(cmake_args) $(src_dir)`)
    run(`cmake --build . --config Release`)
end

println("Build complete!")
