# Semigroups.jl

Julia bindings for the [libsemigroups](https://libsemigroups.readthedocs.io/) C++ library

## Overview

Semigroups.jl provides a Julia interface to libsemigroups through two components:

- **libsemigroups_julia** - A C++ glue library that wraps libsemigroups using CxxWrap
- **Semigroups.jl** - The Julia package providing a high-level, idiomatic Julia API

## Installation

### Prerequisites

1. **Julia** ≥ 1.9
2. **libsemigroups** installed system-wide (tested with version ≥ 3.2.0)
3. **CMake** ≥ 3.15
4. **C++17 compiler**

### Installing Semigroups.jl

Currently, this package is under development. To install from the local repository:

```julia
using Pkg
Pkg.develop(path="/path/to/Semigroups.jl")
```

The C++ glue library (`libsemigroups_julia`) will be automatically built during package precompilation.

```julia
Pkg.precompile()
```

## Tests

With the package installed, the tests can be run with:

```julia
Pkg.test()
```

Or as a one-liner:

```julia
julia --project=. -e 'using Pkg; Pkg.test()'
```

This should be expanded to a more robust test suite as the package grows.
