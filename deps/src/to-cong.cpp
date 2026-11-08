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

// CRITICAL: libsemigroups_julia.hpp MUST be included first (fmt consteval fix)
#include "libsemigroups_julia.hpp"
#include "presentation-conversion.hpp"

#include <cstdint>

#include <libsemigroups/cong-class.hpp>         // for Congruence
#include <libsemigroups/froidure-pin-base.hpp>  // for FroidurePinBase
#include <libsemigroups/to-cong.hpp>            // for to<Congruence<Word>>
#include <libsemigroups/types.hpp>       // for congruence_kind, word_type
#include <libsemigroups/word-graph.hpp>  // for WordGraph

namespace libsemigroups_julia {
  template <typename Word>
  void align_graph_congruence_alphabet(libsemigroups::Congruence<Word>& c,
                                       libsemigroups::congruence_kind   kind) {
    auto const& p = c.presentation();
    check_presentation_alphabet(p);
    auto tc = c.template get<libsemigroups::ToddCoxeter<Word>>();
    if (tc->presentation().alphabet() != p.alphabet()
        || tc->presentation().contains_empty_word()
               != p.contains_empty_word()) {
      // v3.6.1 generates the outer string alphabet consecutively from 'a',
      // but its graph runner uses human-readable order (a-zA-Z...). Align
      // the fresh runner with the outer presentation before it sees words.
      // Copy first: ToddCoxeter rejects reinitialization from its own graph.
      libsemigroups::WordGraph<uint32_t> graph(tc->current_word_graph());
      tc->init(kind, p, graph);
    }
  }

  template <typename Word>
  void define_to_cong_type(jl::Module& m,
                           char const* fp_name,
                           char const* graph_name) {
    using C = libsemigroups::Congruence<Word>;
    m.method(fp_name,
             [](libsemigroups::congruence_kind            knd,
                libsemigroups::FroidurePinBase&           fpb,
                libsemigroups::WordGraph<uint32_t> const& wg) -> C {
               C result = libsemigroups::to<C>(knd, fpb, wg);
               align_graph_congruence_alphabet(result, knd);
               return result;
             });
    m.method(graph_name,
             [](libsemigroups::congruence_kind            knd,
                libsemigroups::WordGraph<uint32_t> const& wg) -> C {
               C result = libsemigroups::to<C>(knd, wg);
               align_graph_congruence_alphabet(result, knd);
               return result;
             });
  }

  void define_to_cong(jl::Module& m) {
    define_to_cong_type<libsemigroups::word_type>(
        m, "to_congruence_from_fpb", "to_congruence_from_wg");
    define_to_cong_type<std::string>(
        m, "to_congruence_from_fpb_string", "to_congruence_from_wg_string");
  }
}  // namespace libsemigroups_julia
