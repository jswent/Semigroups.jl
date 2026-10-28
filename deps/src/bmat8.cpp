//
// Semigroups.jl
// Copyright (C) 2026 James D. Mitchell
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

#include <libsemigroups/bmat8.hpp>

// NOTE: the IsMirroredType<BMat8> specialisation lives in
// libsemigroups_julia.hpp so that every translation unit sees it.

namespace libsemigroups_julia {

  void define_bmat8(jl::Module& m) {
    using namespace libsemigroups;

    auto type = m.add_type<BMat8>("BMat8");

    type.constructor<>();

    ////////////////////////////////////////////////////////////////////////
    // BMat8 mem fns
    ////////////////////////////////////////////////////////////////////////

    m.method("BMat8", [](uint64_t mat) -> BMat8 { return BMat8(mat); });

    type.method("add", [](BMat8 const& self, BMat8 const& that) {
      return self + that;
    });
    type.method("add!", [](BMat8& self, BMat8 const& that) { self += that; });
    type.method("at", [](BMat8 const& self, size_t r) {
      return bmat8::to_vector(self.at(r));
    });
    type.method("at", [](BMat8 const& self, size_t r, size_t c) -> bool {
      return self.at(r, c);
    });
    type.method("copy", [](BMat8 const& self) { return BMat8(self); });
    type.method("degree", [](BMat8 const& self) { return 8; });
    type.method("hash_value", [](BMat8 const& x) { return Hash<BMat8>()(x); });
    type.method("is_greater",
                [](BMat8 const& a, BMat8 const& b) -> bool { return a > b; });
    type.method("is_greater_equal",
                [](BMat8 const& a, BMat8 const& b) -> bool { return a >= b; });
    type.method("is_equal",
                [](BMat8 const& a, BMat8 const& b) -> bool { return a == b; });
    type.method("swap", &BMat8::swap);
    type.method("is_less",
                [](BMat8 const& a, BMat8 const& b) -> bool { return a < b; });
    type.method("is_less_equal",
                [](BMat8 const& a, BMat8 const& b) -> bool { return a <= b; });
    type.method("is_not_equal",
                [](BMat8 const& a, BMat8 const& b) -> bool { return a != b; });

    type.method(
        "multiply_bmat8_bmat8",
        [](BMat8 const& self, BMat8 const& that) { return self * that; });

    type.method("multiply_bmat8_bool",
                [](BMat8 const& self, bool val) { return self * val; });
    type.method("multiply_bool_bmat8",
                [](bool val, BMat8 const& self) { return val * self; });
    // type.method("multiply_bmat8_bmat8!",
    //             [](BMat8& self, BMat8 const& that) { self *= that; });
    // type.method("multiply_bmat8_bool!",
    //             [](BMat8& self, bool scalar) { self *= scalar; });

    // These last two are a little out of pattern from those above.
    type.method("bmat8_setitem", [](BMat8& self, size_t r, size_t c, bool val) {
      self.at(r, c) = val;
    });

    type.method("bmat8_setrow",
                [](BMat8& self, size_t r, jlcxx::ArrayRef<uint8_t> row) {
                  for (size_t c = 0; c < row.size(); c++) {
                    self.at(r, c) = row[c];
                  }
                });

    ////////////////////////////////////////////////////////////////////////
    // BMat8 helpers in libsemigroups namespace
    ////////////////////////////////////////////////////////////////////////

    type.method("to_human_readable_repr",
                [](BMat8 const& x) { return to_human_readable_repr(x, "[]"); });
    type.method("to_int", &BMat8::to_int);

    ////////////////////////////////////////////////////////////////////////
    // BMat8 helpers in bmat8 namespace
    ////////////////////////////////////////////////////////////////////////

    m.method("bmat8_col_space_basis", &bmat8::col_space_basis);
    m.method("bmat8_col_space_size",
             [](BMat8 const& x) { return bmat8::col_space_size(x); });
    m.method("bmat8_is_regular_element",
             [](BMat8 const& x) { return bmat8::is_regular_element(x); });
    m.method("bmat8_minimum_dim",
             [](BMat8 const& x) { return bmat8::minimum_dim(x); });
    m.method("bmat8_number_of_cols",
             [](BMat8 const& x) { return bmat8::number_of_cols(x); });
    m.method("bmat8_number_of_rows",
             [](BMat8 const& x) { return bmat8::number_of_rows(x); });
    m.method("bmat8_one", &bmat8::one<BMat8>);
    m.method("bmat8_random", [](size_t dim) { return bmat8::random(dim); });
    m.method("bmat8_row_space_basis", &bmat8::row_space_basis);
    m.method("bmat8_row_space_size",
             [](BMat8 const& x) { return bmat8::row_space_size(x); });
    m.method("bmat8_rows", [](BMat8 const& x) {
      std::vector<std::vector<bool>> result;
      for (auto row : bmat8::rows(x)) {
        result.push_back(bmat8::to_vector(row));
      }
      return result;
    });
    m.method("bmat8_transpose",
             [](BMat8 const& x) { return bmat8::transpose(x); });

  }  // define_bmat8
}  // namespace libsemigroups_julia
