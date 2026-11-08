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

// cong-class.hpp + cong-helpers.hpp MUST come BEFORE cong-common.hpp so the
// template bodies in cong-common.hpp see Congruence-specific overloads of
// congruence_common helpers at instantiation time.
#include <libsemigroups/cong-class.hpp>
#include <libsemigroups/cong-helpers.hpp>
#include <libsemigroups/kambites-class.hpp>
#include <libsemigroups/knuth-bendix-class.hpp>
// knuth-bendix-helpers.hpp brings `congruence_common::normal_forms` and
// `non_trivial_classes` declarations into scope, which the templates in
// cong-common.hpp reference by qualified name at parse time. Removing
// it breaks the build even though we never instantiate those templates
// for Congruence.
#include <libsemigroups/knuth-bendix-helpers.hpp>
#include <libsemigroups/presentation.hpp>
#include <libsemigroups/todd-coxeter-class.hpp>

#include "cong-common.hpp"

#include <cstddef>
#include <cstdint>
#include <memory>
#include <string>
#include <type_traits>
#include <vector>

namespace jlcxx {
  template <typename Word>
  struct IsMirroredType<libsemigroups::Congruence<Word>> : std::false_type {};

  template <typename Word>
  struct SuperType<libsemigroups::Congruence<Word>> {
    using type = libsemigroups::detail::CongruenceCommon;
  };
}  // namespace jlcxx

namespace libsemigroups_julia {

  // Templated helper that binds the `has<Thing>()` / `get<Thing>()` member
  // templates of `Congruence<Word>` as named module methods. CxxWrap
  // cannot bind C++ template member functions directly; we instantiate a
  // separate pair of named methods per `Thing` and dispatch from the Julia
  // side on `::Type{T}`.
  template <typename Word, typename Thing>
  inline void define_cong_has_get(jl::Module& m, std::string const& suffix) {
    using Cong = libsemigroups::Congruence<Word>;
    m.method("cong_has_" + suffix,
             [](Cong const& c) -> bool { return c.template has<Thing>(); });
    m.method("cong_get_" + suffix, [](Cong const& c) -> jl::BoxedValue<Thing> {
      // Construct the owning result in place: moving a completed
      // KnuthBendix in libsemigroups 3.6.1 invalidates rule cursors.
      return jl::create<Thing>(*c.template get<Thing>());
    });
  }

  template <typename Word>
  void define_congruence_type(jl::Module& m, std::string const& name) {
    using libsemigroups::Congruence;
    using libsemigroups::congruence_kind;
    using libsemigroups::Kambites;
    using libsemigroups::KnuthBendix;
    using libsemigroups::Presentation;
    using libsemigroups::ToddCoxeter;

    using CongruenceCommon = libsemigroups::detail::CongruenceCommon;
    using C                = Congruence<Word>;

    ////////////////////////////////////////////////////////////////////////
    // Type registration
    ////////////////////////////////////////////////////////////////////////

    auto type = m.add_type<C>(name, jlcxx::julia_base_type<CongruenceCommon>());

    ////////////////////////////////////////////////////////////////////////
    // Constructors. Julia adapters translate native construction errors.
    ////////////////////////////////////////////////////////////////////////

    type.template constructor<>();
    type.template constructor<congruence_kind, Presentation<Word> const&>();
    type.template constructor<C const&>();  // copy ctor

    ////////////////////////////////////////////////////////////////////////
    // init! overloads (mirror constructors)
    ////////////////////////////////////////////////////////////////////////

    type.method("init!", [](C& self) -> C& { return self.init(); });
    type.method(
        "init!",
        [](C& self, congruence_kind knd, Presentation<Word> const& p) -> C& {
          return self.init(knd, p);
        });

    ////////////////////////////////////////////////////////////////////////
    // Accessors
    ////////////////////////////////////////////////////////////////////////

    // presentation - return by copy (storage may relocate)
    type.method("presentation", [](C const& self) -> Presentation<Word> {
      return self.presentation();
    });

    // generating_pairs - return by copy (flat vector; pairs concatenated)
    type.method("generating_pairs", [](C const& self) -> std::vector<Word> {
      auto const& pairs = self.generating_pairs();
      return std::vector<Word>(pairs.begin(), pairs.end());
    });

    // kind / number_of_generating_pairs -- inherited inline accessors
    type.method("kind",
                [](C const& self) -> congruence_kind { return self.kind(); });

    type.method("number_of_generating_pairs", [](C const& self) -> size_t {
      return self.number_of_generating_pairs();
    });

    // number_of_classes - non-const (may run the race)
    type.method("number_of_classes",
                [](C& self) -> uint64_t { return self.number_of_classes(); });

    // Validate against the stored presentation alphabet.
    type.method("throw_if_letter_not_in_alphabet",
                [](C const& self, WordInput<Word> w) {
                  Word ww = native_word<Word>(w);
                  self.throw_if_letter_not_in_alphabet(ww.begin(), ww.end());
                });

    ////////////////////////////////////////////////////////////////////////
    // Race-state queries
    // (max_threads getter/setter intentionally NOT bound)
    ////////////////////////////////////////////////////////////////////////

    type.method("number_of_runners", [](C const& self) -> size_t {
      return self.number_of_runners();
    });

    ////////////////////////////////////////////////////////////////////////
    // Race introspection: has<Thing>() / get<Thing>()
    ////////////////////////////////////////////////////////////////////////

    define_cong_has_get<Word, Kambites<Word>>(m, "kambites");
    define_cong_has_get<Word, KnuthBendix<Word>>(m, "knuth_bendix");
    define_cong_has_get<Word, ToddCoxeter<Word>>(m, "todd_coxeter");

    ////////////////////////////////////////////////////////////////////////
    // Free function: is_obviously_infinite
    ////////////////////////////////////////////////////////////////////////

    m.method("is_obviously_infinite", [](C const& c) -> bool {
      return libsemigroups::is_obviously_infinite(c);
    });

    ////////////////////////////////////////////////////////////////////////
    // Display
    ////////////////////////////////////////////////////////////////////////

    type.method("to_human_readable_repr", [](C const& self) -> std::string {
      return libsemigroups::to_human_readable_repr(self);
    });

    ////////////////////////////////////////////////////////////////////////
    // Cong-common helpers (word-helpers subset only).
    ////////////////////////////////////////////////////////////////////////

    define_cong_common_word_helpers<C>(m);
  }

  void define_congruence(jl::Module& m) {
    define_congruence_type<libsemigroups::word_type>(m, "CongruenceWord");
    define_congruence_type<std::string>(m, "CongruenceString");
  }

}  // namespace libsemigroups_julia
