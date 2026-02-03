// libsemigroups_julia.hpp - Common includes and declarations for
// libsemigroups_julia
//
// This file provides the common includes and forward declarations used
// throughout the Julia bindings for libsemigroups.

#ifndef LIBSEMIGROUPS_JULIA_HPP_
#define LIBSEMIGROUPS_JULIA_HPP_

// JlCxx headers
#include "jlcxx/jlcxx.hpp"
#include "jlcxx/stl.hpp"

// libsemigroups headers
#include <libsemigroups/constants.hpp>
#include <libsemigroups/types.hpp>

// Standard library
#include <sstream>
#include <stdexcept>
#include <string>
#include <vector>

namespace libsemigroups_julia {

// Namespace aliases for convenience
namespace jl = jlcxx;
namespace libsemigroups = ::libsemigroups;

// Forward declarations of binding functions
void define_constants(jl::Module & mod);
void define_transf(jl::Module & mod);

}    // namespace libsemigroups_julia

#endif    // LIBSEMIGROUPS_JULIA_HPP_
