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

#include "libsemigroups_julia.hpp"

namespace libsemigroups_julia {

void define_constants(jl::Module & m)
{
  // UNDEFINED values for different integer types
  // UNDEFINED represents max value of the type
  m.method("UNDEFINED_UInt8", []() -> uint8_t {
    return libsemigroups::UNDEFINED;
  });
  m.method("UNDEFINED_UInt16", []() -> uint16_t {
    return libsemigroups::UNDEFINED;
  });
  m.method("UNDEFINED_UInt32", []() -> uint32_t {
    return libsemigroups::UNDEFINED;
  });
  m.method("UNDEFINED_UInt64", []() -> uint64_t {
    return libsemigroups::UNDEFINED;
  });
  m.method("UNDEFINED_Int64", []() -> int64_t {
    return libsemigroups::UNDEFINED;
  });

  // POSITIVE_INFINITY values for different integer types
  // POSITIVE_INFINITY represents max-1 value of the type
  m.method("POSITIVE_INFINITY_UInt8", []() -> uint8_t {
    return libsemigroups::POSITIVE_INFINITY;
  });
  m.method("POSITIVE_INFINITY_UInt16", []() -> uint16_t {
    return libsemigroups::POSITIVE_INFINITY;
  });
  m.method("POSITIVE_INFINITY_UInt32", []() -> uint32_t {
    return libsemigroups::POSITIVE_INFINITY;
  });
  m.method("POSITIVE_INFINITY_UInt64", []() -> uint64_t {
    return libsemigroups::POSITIVE_INFINITY;
  });
  m.method("POSITIVE_INFINITY_Int64", []() -> int64_t {
    return libsemigroups::POSITIVE_INFINITY;
  });

  // LIMIT_MAX values for different integer types
  // LIMIT_MAX represents max-2 value of the type
  m.method("LIMIT_MAX_UInt8", []() -> uint8_t {
    return libsemigroups::LIMIT_MAX;
  });
  m.method("LIMIT_MAX_UInt16", []() -> uint16_t {
    return libsemigroups::LIMIT_MAX;
  });
  m.method("LIMIT_MAX_UInt32", []() -> uint32_t {
    return libsemigroups::LIMIT_MAX;
  });
  m.method("LIMIT_MAX_UInt64", []() -> uint64_t {
    return libsemigroups::LIMIT_MAX;
  });
  m.method("LIMIT_MAX_Int64", []() -> int64_t {
    return libsemigroups::LIMIT_MAX;
  });

  // NEGATIVE_INFINITY for signed types
  m.method("NEGATIVE_INFINITY_Int8", []() -> int8_t {
    return libsemigroups::NEGATIVE_INFINITY;
  });
  m.method("NEGATIVE_INFINITY_Int16", []() -> int16_t {
    return libsemigroups::NEGATIVE_INFINITY;
  });
  m.method("NEGATIVE_INFINITY_Int32", []() -> int32_t {
    return libsemigroups::NEGATIVE_INFINITY;
  });
  m.method("NEGATIVE_INFINITY_Int64", []() -> int64_t {
    return libsemigroups::NEGATIVE_INFINITY;
  });

  // tril enum for three-valued logic (true, false, unknown)
  m.add_bits<libsemigroups::tril>("tril", jl::julia_type("CppEnum"));
  m.set_const("tril_FALSE", libsemigroups::tril::FALSE);
  m.set_const("tril_TRUE", libsemigroups::tril::TRUE);
  m.set_const("tril_unknown", libsemigroups::tril::unknown);

  // Helper to convert tril to Julia Bool or nothing
  m.method("tril_to_bool", [](libsemigroups::tril t) -> jl_value_t * {
    if (t == libsemigroups::tril::TRUE)
    {
      return jl_box_bool(true);
    }
    else if (t == libsemigroups::tril::FALSE)
    {
      return jl_box_bool(false);
    }
    else
    {
      return jl_nothing;
    }
  });
}

}    // namespace libsemigroups_julia
