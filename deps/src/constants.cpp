// constants.cpp - Constant bindings for libsemigroups_julia
//
// This file exposes libsemigroups constants (UNDEFINED, POSITIVE_INFINITY,
// etc.) to Julia. Since these are template-based types that convert to
// integers, we expose them as functions returning the appropriate values.

#include "libsemigroups_julia.hpp"

namespace libsemigroups_julia {

void define_constants(jl::Module &mod) {
  // UNDEFINED values for different integer types
  // UNDEFINED represents max value of the type
  mod.method("UNDEFINED_UInt8",
             []() -> uint8_t { return libsemigroups::UNDEFINED; });
  mod.method("UNDEFINED_UInt16",
             []() -> uint16_t { return libsemigroups::UNDEFINED; });
  mod.method("UNDEFINED_UInt32",
             []() -> uint32_t { return libsemigroups::UNDEFINED; });
  mod.method("UNDEFINED_UInt64",
             []() -> uint64_t { return libsemigroups::UNDEFINED; });
  mod.method("UNDEFINED_Int64",
             []() -> int64_t { return libsemigroups::UNDEFINED; });

  // POSITIVE_INFINITY values for different integer types
  // POSITIVE_INFINITY represents max-1 value of the type
  mod.method("POSITIVE_INFINITY_UInt8",
             []() -> uint8_t { return libsemigroups::POSITIVE_INFINITY; });
  mod.method("POSITIVE_INFINITY_UInt16",
             []() -> uint16_t { return libsemigroups::POSITIVE_INFINITY; });
  mod.method("POSITIVE_INFINITY_UInt32",
             []() -> uint32_t { return libsemigroups::POSITIVE_INFINITY; });
  mod.method("POSITIVE_INFINITY_UInt64",
             []() -> uint64_t { return libsemigroups::POSITIVE_INFINITY; });
  mod.method("POSITIVE_INFINITY_Int64",
             []() -> int64_t { return libsemigroups::POSITIVE_INFINITY; });

  // LIMIT_MAX values for different integer types
  // LIMIT_MAX represents max-2 value of the type
  mod.method("LIMIT_MAX_UInt8",
             []() -> uint8_t { return libsemigroups::LIMIT_MAX; });
  mod.method("LIMIT_MAX_UInt16",
             []() -> uint16_t { return libsemigroups::LIMIT_MAX; });
  mod.method("LIMIT_MAX_UInt32",
             []() -> uint32_t { return libsemigroups::LIMIT_MAX; });
  mod.method("LIMIT_MAX_UInt64",
             []() -> uint64_t { return libsemigroups::LIMIT_MAX; });
  mod.method("LIMIT_MAX_Int64",
             []() -> int64_t { return libsemigroups::LIMIT_MAX; });

  // NEGATIVE_INFINITY for signed types
  mod.method("NEGATIVE_INFINITY_Int8",
             []() -> int8_t { return libsemigroups::NEGATIVE_INFINITY; });
  mod.method("NEGATIVE_INFINITY_Int16",
             []() -> int16_t { return libsemigroups::NEGATIVE_INFINITY; });
  mod.method("NEGATIVE_INFINITY_Int32",
             []() -> int32_t { return libsemigroups::NEGATIVE_INFINITY; });
  mod.method("NEGATIVE_INFINITY_Int64",
             []() -> int64_t { return libsemigroups::NEGATIVE_INFINITY; });

  // tril enum for three-valued logic (true, false, unknown)
  mod.add_bits<libsemigroups::tril>("tril", jl::julia_type("CppEnum"));
  mod.set_const("tril_FALSE", libsemigroups::tril::FALSE);
  mod.set_const("tril_TRUE", libsemigroups::tril::TRUE);
  mod.set_const("tril_unknown", libsemigroups::tril::unknown);

  // Helper to convert tril to Julia Bool or nothing
  mod.method("tril_to_bool", [](libsemigroups::tril t) -> jl_value_t * {
    if (t == libsemigroups::tril::TRUE) {
      return jl_box_bool(true);
    } else if (t == libsemigroups::tril::FALSE) {
      return jl_box_bool(false);
    } else {
      return jl_nothing;
    }
  });
}

} // namespace libsemigroups_julia
