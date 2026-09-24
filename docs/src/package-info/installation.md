# Installation

## Requirements

- Julia 1.10 or later

## Installing `Semigroups.jl`

To install `Semigroups.jl` from GitHub:

```julia
using Pkg
Pkg.add(url="https://github.com/libsemigroups/Semigroups.jl")
```

The required C++ libraries are bundled via binary packages and will be
downloaded automatically during installation.

## Verifying the Installation

```julia
using Semigroups

t = Transf([2, 3, 1])
println(degree(t))  # 3
println(t ^ 3)      # Transf([1, 2, 3])
```

## Troubleshooting

If you encounter problems loading the package, try rebuilding:

```julia
using Pkg
Pkg.build("Semigroups"; verbose=true)
```

## Building from Source

To build from a local clone (for development):

```julia
using Pkg
Pkg.develop(path="/path/to/Semigroups.jl")
```

This requires:

- CMake 3.15 or later
- A C++17 compatible compiler (GCC 7+, Clang 5+, or MSVC 2017+)
