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

#include <libsemigroups/exception.hpp>

// kambites-class.hpp and kambites-helpers.hpp MUST come BEFORE cong-common.hpp
// so the template bodies in cong-common.hpp see Kambites-specific overloads of
// congruence_common helpers. ADL resolves these at template-instantiation time;
// see the include-order requirement documented at cong-common.hpp:27-38.
#include <libsemigroups/kambites-class.hpp>
#include <libsemigroups/kambites-helpers.hpp>

// Required for `congruence_common::normal_forms(Kambites&)` (used by the
// `kambites_normal_forms_take` binding below). The returned
// `KambitesNormalFormRange::init` calls `libsemigroups::to<FroidurePin>(k)`,
// whose template definition lives in to-froidure-pin.tpp (transitively
// included by to-froidure-pin.hpp). Without this header, the binding compiles
// but fails to link with an undefined `libsemigroups::to<FroidurePin, ...>`
// symbol.
#include <libsemigroups/to-froidure-pin.hpp>

#include "cong-common.hpp"

#include <cstddef>
#include <cstdint>
#include <string>
#include <type_traits>
#include <vector>

namespace jlcxx {
  template <typename Word>
  struct IsMirroredType<libsemigroups::Kambites<Word>> : std::false_type {};

  template <typename Word>
  struct SuperType<libsemigroups::Kambites<Word>> {
    using type = libsemigroups::detail::CongruenceCommon;
  };
}  // namespace jlcxx

namespace libsemigroups_julia {

  template <typename Word>
  void define_kambites_type(jl::Module& m, std::string const& name) {
    using libsemigroups::congruence_kind;
    using libsemigroups::Presentation;

    using CongruenceCommon = libsemigroups::detail::CongruenceCommon;
    using K                = libsemigroups::Kambites<Word>;

    // Type registration
    auto type = m.add_type<K>(name, jlcxx::julia_base_type<CongruenceCommon>());

    // Constructors. Direct registration (no defensive lambda); CxxWrap
    // converts C++ exceptions through the std::function path for direct
    // constructor bindings.
    type.template constructor<>();
    type.template constructor<congruence_kind, Presentation<Word> const&>();
    type.template constructor<K const&>();  // copy ctor

    // init! overloads (mirror constructors)
    type.method("init!", [](K& self) -> K& { return self.init(); });
    type.method(
        "init!",
        [](K& self, congruence_kind knd, Presentation<Word> const& p) -> K& {
          return self.init(knd, p);
        });

    // presentation - return by copy (storage may relocate)
    type.method("presentation", [](K const& self) -> Presentation<Word> {
      return self.presentation();
    });

    // generating_pairs - return by copy
    type.method("generating_pairs", [](K const& self) -> std::vector<Word> {
      auto const& pairs = self.generating_pairs();
      return std::vector<Word>(pairs.begin(), pairs.end());
    });

    // kind / number_of_generating_pairs (inherited; exposed for parity with TC)
    type.method("kind",
                [](K const& self) -> congruence_kind { return self.kind(); });

    type.method("number_of_generating_pairs", [](K const& self) -> size_t {
      return self.number_of_generating_pairs();
    });

    // number_of_classes
    type.method("number_of_classes",
                [](K& self) -> uint64_t { return self.number_of_classes(); });

    // Const-overload split (kambites-class.hpp:731-744): the two
    // small_overlap_class() overloads differ only on receiver const-ness, which
    // CxxWrap cannot dispatch. Split into two distinctly-named Julia methods.
    //
    // small_overlap_class -- mutable variant (calls run, returns the class).
    type.method("small_overlap_class",
                [](K& self) -> size_t { return self.small_overlap_class(); });

    // current_small_overlap_class -- const variant (returns UNDEFINED if
    // unknown). Receiver-by-const-ref selects the const overload.
    type.method("current_small_overlap_class", [](K const& self) -> size_t {
      return self.small_overlap_class();
    });

    // throw_if_not_C4 -- bind only the mutable overload, const deferred
    type.method("throw_if_not_C4", [](K& self) { self.throw_if_not_C4(); });

    // TODO: ukkonen() is intentionally NOT bound: its return type is the
    // Ukkonen suffix-tree class, which is currently not bound

    // Validate against the stored presentation alphabet.
    type.method("throw_if_letter_not_in_alphabet",
                [](K const& self, WordInput<Word> w) {
                  Word ww = native_word<Word>(w);
                  self.throw_if_letter_not_in_alphabet(ww.begin(), ww.end());
                });

    // Display
    type.method("to_human_readable_repr", [](K const& self) -> std::string {
      return libsemigroups::to_human_readable_repr(self);
    });

    // Cong common helper subset - DO NOT call aggregator
    define_cong_common_word_helpers<K>(m);

    // Defense: register a throwing `cong_common_normal_forms` for
    // Kambites so the abstract-supertype dispatch path in
    // `src/cong-common.jl::normal_forms(::CongruenceCommon)` raises a clear
    // LibsemigroupsError if it is ever reached on a Kambites value (rather
    // than CxxWrap's opaque method-not-found error). The user-facing
    // `normal_forms(::Kambites)` override in `src/kambites.jl` already
    // throws ArgumentError for direct calls; this guards the indirect path.
    m.method("cong_common_normal_forms", [](K&) -> std::vector<Word> {
      throw libsemigroups::LibsemigroupsException(
          __FILE__,
          __LINE__,
          __func__,
          "Kambites has infinitely many normal forms; use "
          "kambites_normal_forms_take (or normal_forms(k, n) on "
          "the Julia side) to materialize a finite prefix.");
    });

    // Bounded normal_forms binding (Kambites-specific). Mirrors the cong-common
    // normal_forms template but caps iteration at n elements so callers can
    // safely take a finite prefix of the infinite normal-form range.
    m.method("kambites_normal_forms_take",
             [](K& self, size_t n) -> std::vector<Word> {
               std::vector<Word> result;
               result.reserve(n);
               auto range
                   = libsemigroups::congruence_common::normal_forms(self);
               for (size_t i = 0; i < n && !range.at_end(); ++i) {
                 result.push_back(range.get());
                 range.next();
               }
               return result;
             });
  }

  void define_kambites(jl::Module& m) {
    define_kambites_type<libsemigroups::word_type>(m, "KambitesWord");
    define_kambites_type<std::string>(m, "KambitesString");
  }

}  // namespace libsemigroups_julia
