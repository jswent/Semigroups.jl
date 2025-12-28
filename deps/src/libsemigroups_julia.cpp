// libsemigroups_julia.cpp - Main JLCXX_MODULE entry point for
// libsemigroups_julia
//
// This file defines the main Julia module that wraps libsemigroups
// functionality.

#include "libsemigroups_julia.hpp"

namespace libsemigroups_julia {

JLCXX_MODULE define_julia_module(jl::Module & mod)
{
  // Define constants first (UNDEFINED, POSITIVE_INFINITY, etc.)
  define_constants(mod);

  // Define error handling
  define_errors(mod);

  // Define element types
  define_transf(mod);

  // Add more definitions here (FroidurePin, etc.)
}

}    // namespace libsemigroups_julia
