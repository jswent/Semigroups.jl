//
// Semigroups.jl
// Copyright (C) 2026, Joseph E. Macgowan
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

// CRITICAL: libsemigroups_julia.hpp MUST be included first (fmt consteval fix)
#include "libsemigroups_julia.hpp"
#include "presentation-conversion.hpp"

#include <libsemigroups/froidure-pin-base.hpp>
#include <libsemigroups/knuth-bendix-class.hpp>
#include <libsemigroups/to-knuth-bendix.hpp>
#include <libsemigroups/todd-coxeter-class.hpp>
#include <libsemigroups/types.hpp>

namespace libsemigroups_julia {
  template <typename Word, typename SourceWord>
  void define_tc_to_kb(jl::Module& m, char const* name) {
    using KB = libsemigroups::KnuthBendix<Word>;
    m.method(
        name,
        [](libsemigroups::congruence_kind          knd,
           libsemigroups::ToddCoxeter<SourceWord>& tc) -> jl::BoxedValue<KB> {
          return jl::create<KB>(knd,
                                convert_presentation<Word>(tc.presentation()));
        });
  }

  template <typename Word>
  void define_to_knuth_bendix_type(jl::Module& m,
                                   char const* fp_name,
                                   char const* tc_name) {
    using KB = libsemigroups::KnuthBendix<Word>;
    m.method(fp_name,
             [](libsemigroups::congruence_kind  knd,
                libsemigroups::FroidurePinBase& fpb) -> jl::BoxedValue<KB> {
               auto p = froidure_pin_presentation<Word>(fpb);
               return jl::create<KB>(knd, std::move(p));
             });
    define_tc_to_kb<Word, libsemigroups::word_type>(m, tc_name);
    define_tc_to_kb<Word, std::string>(m, tc_name);
  }

  void define_to_knuth_bendix(jl::Module& m) {
    define_to_knuth_bendix_type<libsemigroups::word_type>(
        m, "to_knuth_bendix_from_fpb", "to_knuth_bendix_from_tc");
    define_to_knuth_bendix_type<std::string>(
        m, "to_knuth_bendix_from_fpb_string", "to_knuth_bendix_from_tc_string");
  }
}  // namespace libsemigroups_julia
