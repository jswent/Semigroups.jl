//
// Semigroups.jl
// Copyright (C) 2026, James W. Swent
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
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
