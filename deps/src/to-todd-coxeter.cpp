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

#include <cstdint>

#include <libsemigroups/froidure-pin-base.hpp>
#include <libsemigroups/knuth-bendix-class.hpp>
#include <libsemigroups/to-froidure-pin.hpp>
#include <libsemigroups/to-presentation.hpp>
#include <libsemigroups/to-todd-coxeter.hpp>
#include <libsemigroups/types.hpp>
#include <libsemigroups/word-graph.hpp>

namespace libsemigroups_julia {
  template <typename Word, typename SourceWord>
  void define_kb_to_tc(jl::Module& m, char const* name) {
    using TC    = libsemigroups::ToddCoxeter<Word>;
    using KB    = libsemigroups::KnuthBendix<SourceWord>;
    using Graph = libsemigroups::WordGraph<uint32_t>;
    m.method(
        name,
        [](libsemigroups::congruence_kind knd, KB& kb) -> jl::BoxedValue<TC> {
          if (kb.kind() != libsemigroups::congruence_kind::twosided) {
            throw std::invalid_argument(
                "the KnuthBendix source must be a two-sided congruence");
          }
          if (kb.number_of_classes() == libsemigroups::POSITIVE_INFINITY) {
            throw std::invalid_argument(
                "cannot construct ToddCoxeter using the Cayley graph of an "
                "infinite KnuthBendix object");
          }
          auto p = libsemigroups::to<libsemigroups::Presentation<Word>>(kb);
          check_presentation_alphabet(p);
          size_t const n = p.alphabet().size();
          if (n == 0) {
            // The empty alphabet has no Cayley edges: the presentation alone
            // distinguishes the empty semigroup from the trivial monoid.
            return jl::create<TC>(knd, p);
          }

          // The native conversion owns a copy of a correctly constructed KB.
          // Our KB factories use jl::create to avoid moving the backend's
          // stateful rewrite-rule cursors across the Julia boundary.
          auto         fp = libsemigroups::to<libsemigroups::FroidurePin>(kb);
          bool const   monoid = p.contains_empty_word();
          auto const&  cayley = fp.right_cayley_graph();
          size_t const offset = monoid ? 0 : 1;
          Graph        graph(fp.size() + offset, n);
          size_t const identity
              = monoid ? fp.position_of_generator_no_checks(n) : 0;
          auto node = [monoid, identity](size_t i) {
            if (!monoid) {
              return i + 1;
            }
            return i == identity ? size_t(0) : (i == 0 ? identity : i);
          };
          for (size_t i = 0; i < fp.size(); ++i) {
            for (size_t a = 0; a < n; ++a) {
              graph.target_no_checks(
                  node(i), a, node(cayley.target_no_checks(i, a)));
            }
          }
          if (!monoid) {
            for (size_t a = 0; a < n; ++a) {
              graph.target_no_checks(
                  0, a, node(fp.position_of_generator_no_checks(a)));
            }
          }
          // Supply the presentation so labels and the empty-word contract
          // survive graph conversion. The artificial identity generator stays
          // internal.
          return jl::create<TC>(knd, p, graph);
        });
  }

  template <typename Word>
  void define_to_todd_coxeter_type(jl::Module& m,
                                   char const* fp_name,
                                   char const* kb_name) {
    using TC = libsemigroups::ToddCoxeter<Word>;
    m.method(fp_name,
             [](libsemigroups::congruence_kind            knd,
                libsemigroups::FroidurePinBase&           fpb,
                libsemigroups::WordGraph<uint32_t> const& wg) -> TC {
               TC result = libsemigroups::to<TC>(knd, fpb, wg);
               check_presentation_alphabet(result.presentation());
               return result;
             });
    define_kb_to_tc<Word, libsemigroups::word_type>(m, kb_name);
    define_kb_to_tc<Word, std::string>(m, kb_name);
  }

  void define_to_todd_coxeter(jl::Module& m) {
    define_to_todd_coxeter_type<libsemigroups::word_type>(
        m, "to_todd_coxeter_from_fpb", "to_todd_coxeter_from_kb");
    define_to_todd_coxeter_type<std::string>(
        m, "to_todd_coxeter_from_fpb_string", "to_todd_coxeter_from_kb_string");
  }
}  // namespace libsemigroups_julia
