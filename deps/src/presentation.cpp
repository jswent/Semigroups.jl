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
#include "word-transport.hpp"

#include <libsemigroups/presentation.hpp>
#include <libsemigroups/types.hpp>

#include <jlcxx/array.hpp>

#include <cstddef>
#include <iterator>
#include <stdexcept>
#include <string>
#include <type_traits>
#include <vector>

namespace jlcxx {
  template <typename Word>
  struct IsMirroredType<libsemigroups::Presentation<Word>> : std::false_type {};

  template <typename Word>
  struct IsMirroredType<libsemigroups::InversePresentation<Word>>
      : std::false_type {};

  template <typename Word>
  struct SuperType<libsemigroups::InversePresentation<Word>> {
    using type = libsemigroups::Presentation<Word>;
  };
}  // namespace jlcxx

namespace libsemigroups_julia {

  template <typename Word>
  void
  check_ascii_generator_capacity(libsemigroups::Presentation<Word> const& p) {
    if constexpr (std::is_same_v<Word, std::string>) {
      if (p.alphabet().size() >= 128) {
        throw std::invalid_argument("the ASCII alphabet has no unused letters");
      }
    }
  }

  template <typename Word>
  void define_presentation_type(jl::Module& m,
                                char const* name,
                                char const* inverse_name) {
    using libsemigroups::Presentation;
    using Letter = NativeLetter<Word>;

    auto type = m.add_type<Presentation<Word>>(name);
    type.template constructor<>();
    type.template constructor<Presentation<Word> const&>();  // copy ctor

    type.method("init!", [](Presentation<Word>& self) { self.init(); });

    type.method("alphabet", [](Presentation<Word> const& self) -> Word {
      return self.alphabet();
    });

    type.method("set_alphabet_size!", [](Presentation<Word>& self, size_t n) {
      if constexpr (std::is_same_v<Word, std::string>) {
        if (n > 31) {
          throw std::invalid_argument(
              "the native string alphabet size constructor supports at most 31 "
              "ASCII letters; provide an explicit alphabet instead");
        }
      }
      self.alphabet(n);
    });

    type.method("set_alphabet!",
                [](Presentation<Word>& self, WordInput<Word> a) {
                  self.alphabet(native_word<Word>(a));
                });

    type.method("alphabet_from_rules!",
                [](Presentation<Word>& self) { self.alphabet_from_rules(); });

    type.method("letter",
                [](Presentation<Word> const& self, size_t i) -> Letter {
                  return bridge_letter<Word>(self.letter(i));
                });

    type.method("index_of",
                [](Presentation<Word> const& self, Letter x) -> size_t {
                  return self.index(native_letter<Word>(x));
                });

    type.method("in_alphabet",
                [](Presentation<Word> const& self, Letter x) -> bool {
                  return self.in_alphabet(native_letter<Word>(x));
                });

    type.method("contains_empty_word",
                [](Presentation<Word> const& self) -> bool {
                  return self.contains_empty_word();
                });
    type.method(
        "set_contains_empty_word!",
        [](Presentation<Word>& self, bool v) { self.contains_empty_word(v); });

    type.method("add_generator_no_arg!",
                [](Presentation<Word>& self) -> Letter {
                  check_ascii_generator_capacity(self);
                  return bridge_letter<Word>(self.add_generator());
                });
    type.method("add_generator!", [](Presentation<Word>& self, Letter x) {
      self.add_generator(native_letter<Word>(x));
    });
    type.method("remove_generator!", [](Presentation<Word>& self, Letter x) {
      self.remove_generator(native_letter<Word>(x));
    });

    m.method(
        "add_rule_no_checks!",
        [](Presentation<Word>& p, WordInput<Word> lhs, WordInput<Word> rhs) {
          Word l = native_word<Word>(lhs);
          Word r = native_word<Word>(rhs);
          libsemigroups::presentation::add_rule_no_checks(p, l, r);
        });

    m.method(
        "add_rule!",
        [](Presentation<Word>& p, WordInput<Word> lhs, WordInput<Word> rhs) {
          Word l = native_word<Word>(lhs);
          Word r = native_word<Word>(rhs);
          libsemigroups::presentation::add_rule(p, l, r);
        });

    type.method("number_of_rules",
                [](Presentation<Word> const& self) -> size_t {
                  return self.rules.size() / 2;
                });

    type.method("rule_lhs",
                [](Presentation<Word> const& self, size_t i) -> Word {
                  return self.rules.at(2 * i);
                });

    type.method("rule_rhs",
                [](Presentation<Word> const& self, size_t i) -> Word {
                  return self.rules.at(2 * i + 1);
                });

    type.method("clear_rules!",
                [](Presentation<Word>& self) { self.rules.clear(); });

    type.method("throw_if_alphabet_has_duplicates",
                [](Presentation<Word> const& self) {
                  self.throw_if_alphabet_has_duplicates();
                });
    type.method("throw_if_letter_not_in_alphabet",
                [](Presentation<Word> const& self, Letter x) {
                  self.throw_if_letter_not_in_alphabet(native_letter<Word>(x));
                });
    type.method("throw_if_bad_rules", [](Presentation<Word> const& self) {
      self.throw_if_bad_rules();
    });
    type.method("throw_if_bad_alphabet_or_rules",
                [](Presentation<Word> const& self) {
                  self.throw_if_bad_alphabet_or_rules();
                });

    m.method("length_of", [](Presentation<Word> const& p) -> size_t {
      return libsemigroups::presentation::length(p);
    });
    m.method("longest_rule_length", [](Presentation<Word> const& p) -> size_t {
      return libsemigroups::presentation::longest_rule_length(p);
    });
    m.method("shortest_rule_length", [](Presentation<Word> const& p) -> size_t {
      return libsemigroups::presentation::shortest_rule_length(p);
    });
    m.method("is_normalized", [](Presentation<Word> const& p) -> bool {
      return libsemigroups::presentation::is_normalized(p);
    });
    m.method("are_rules_sorted", [](Presentation<Word> const& p) -> bool {
      return libsemigroups::presentation::are_rules_sorted(p);
    });
    m.method("contains_rule",
             [](Presentation<Word>& p,
                WordInput<Word>     lhs,
                WordInput<Word>     rhs) -> bool {
               Word l = native_word<Word>(lhs);
               Word r = native_word<Word>(rhs);
               return libsemigroups::presentation::contains_rule(p, l, r);
             });
    m.method("throw_if_odd_number_of_rules", [](Presentation<Word> const& p) {
      // Fully qualified: the iterator-pair overload is also in scope.
      libsemigroups::presentation::throw_if_odd_number_of_rules(p);
    });

    m.method("normalize_alphabet!", [](Presentation<Word>& p) {
      libsemigroups::presentation::normalize_alphabet(p);
    });
    m.method("change_alphabet!", [](Presentation<Word>& p, WordInput<Word> a) {
      libsemigroups::presentation::change_alphabet(p, native_word<Word>(a));
    });
    m.method("reverse_rules!", [](Presentation<Word>& p) {
      libsemigroups::presentation::reverse(p);
    });
    m.method("sort_rules!", [](Presentation<Word>& p) {
      libsemigroups::presentation::sort_rules(p);
    });
    m.method("sort_each_rule!", [](Presentation<Word>& p) -> bool {
      return libsemigroups::presentation::sort_each_rule(p);
    });

    m.method("add_identity_rules!", [](Presentation<Word>& p, Letter e) {
      libsemigroups::presentation::add_identity_rules(p,
                                                      native_letter<Word>(e));
    });
    m.method("add_zero_rules!", [](Presentation<Word>& p, Letter z) {
      libsemigroups::presentation::add_zero_rules(p, native_letter<Word>(z));
    });
    m.method("remove_duplicate_rules!", [](Presentation<Word>& p) {
      libsemigroups::presentation::remove_duplicate_rules(p);
    });
    m.method("remove_trivial_rules!", [](Presentation<Word>& p) {
      libsemigroups::presentation::remove_trivial_rules(p);
    });

    m.method("add_rules!",
             [](Presentation<Word>& p, Presentation<Word> const& q) {
               libsemigroups::presentation::add_rules(p, q);
             });

    m.method("add_inverse_rules!",
             [](Presentation<Word>& p, WordInput<Word> inverses) {
               Word v = native_word<Word>(inverses);
               libsemigroups::presentation::add_inverse_rules(p, v);
             });

    m.method("add_inverse_rules_with_identity!",
             [](Presentation<Word>& p, WordInput<Word> inverses, Letter e) {
               Word v = native_word<Word>(inverses);
               libsemigroups::presentation::add_inverse_rules(
                   p, v, native_letter<Word>(e));
             });

    m.method("replace_subword!",
             [](Presentation<Word>& p,
                WordInput<Word>     existing,
                WordInput<Word>     replacement) {
               Word e = native_word<Word>(existing);
               Word r = native_word<Word>(replacement);
               libsemigroups::presentation::replace_subword(p, e, r);
             });

    m.method("replace_word!",
             [](Presentation<Word>& p,
                WordInput<Word>     existing,
                WordInput<Word>     replacement) {
               Word e = native_word<Word>(existing);
               Word r = native_word<Word>(replacement);
               libsemigroups::presentation::replace_word(p, e, r);
             });

    m.method("replace_word_with_new_generator!",
             [](Presentation<Word>& p, WordInput<Word> w) -> Letter {
               check_ascii_generator_capacity(p);
               Word v = native_word<Word>(w);
               return bridge_letter<Word>(
                   libsemigroups::presentation::replace_word_with_new_generator(
                       p, v));
             });

    m.method("first_unused_letter", [](Presentation<Word> const& p) -> Letter {
      check_ascii_generator_capacity(p);
      return bridge_letter<Word>(
          libsemigroups::presentation::first_unused_letter(p));
    });

    m.method("index_rule",
             [](Presentation<Word> const& p,
                WordInput<Word>           lhs,
                WordInput<Word>           rhs) -> size_t {
               Word l = native_word<Word>(lhs);
               Word r = native_word<Word>(rhs);
               return libsemigroups::presentation::index_rule(p, l, r);
             });

    m.method("is_rule",
             [](Presentation<Word> const& p,
                WordInput<Word>           lhs,
                WordInput<Word>           rhs) -> bool {
               Word l = native_word<Word>(lhs);
               Word r = native_word<Word>(rhs);
               return libsemigroups::presentation::is_rule(p, l, r);
             });

    m.method("longest_rule_index", [](Presentation<Word> const& p) -> size_t {
      auto it = libsemigroups::presentation::longest_rule(p);
      return static_cast<size_t>(std::distance(p.rules.cbegin(), it));
    });

    m.method("shortest_rule_index", [](Presentation<Word> const& p) -> size_t {
      auto it = libsemigroups::presentation::shortest_rule(p);
      return static_cast<size_t>(std::distance(p.rules.cbegin(), it));
    });

    m.method("throw_if_bad_inverses",
             [](Presentation<Word> const& p, WordInput<Word> inverses) {
               Word v = native_word<Word>(inverses);
               libsemigroups::presentation::throw_if_bad_inverses(p, v);
             });

    m.method("to_gap_string",
             [](Presentation<Word> const& p,
                std::string const&        var_name) -> std::string {
               return libsemigroups::presentation::to_gap_string(p, var_name);
             });

    m.method("rules_vector",
             [](Presentation<Word> const& p) -> std::vector<Word> {
               return std::vector<Word>(p.rules.cbegin(), p.rules.cend());
             });

    type.method("is_equal",
                [](Presentation<Word> const& a,
                   Presentation<Word> const& b) -> bool { return a == b; });
    type.method("to_human_readable_repr",
                [](Presentation<Word> const& p) -> std::string {
                  return libsemigroups::to_human_readable_repr(p);
                });

    // -----------------------------------------------------------------------
    // InversePresentation<Word>
    // -----------------------------------------------------------------------
    using libsemigroups::InversePresentation;

    auto itype = m.add_type<InversePresentation<Word>>(
        inverse_name, jlcxx::julia_base_type<Presentation<Word>>());

    itype.template constructor<Presentation<Word> const&>();
    itype
        .template constructor<InversePresentation<Word> const&>();  // copy ctor

    itype.method("set_inverses!",
                 [](InversePresentation<Word>& self, WordInput<Word> w) {
                   self.inverses(native_word<Word>(w));
                 });
    itype.method("inverses", [](InversePresentation<Word> const& self) -> Word {
      return self.inverses();
    });
    itype.method("inverse_of",
                 [](InversePresentation<Word> const& self, Letter x) -> Letter {
                   return bridge_letter<Word>(
                       self.inverse(native_letter<Word>(x)));
                 });
    itype.method("throw_if_bad_alphabet_rules_or_inverses",
                 [](InversePresentation<Word> const& self) {
                   self.throw_if_bad_alphabet_rules_or_inverses();
                 });
    itype.method(
        "is_equal_inv",
        [](InversePresentation<Word> const& a,
           InversePresentation<Word> const& b) -> bool { return a == b; });
    itype.method("to_human_readable_repr",
                 [](InversePresentation<Word> const& self) -> std::string {
                   return libsemigroups::to_human_readable_repr(self);
                 });
  }

  void define_presentation(jl::Module& m) {
    define_presentation_type<libsemigroups::word_type>(
        m, "Presentation", "InversePresentation");
    define_presentation_type<std::string>(
        m, "PresentationString", "InversePresentationString");
  }

}  // namespace libsemigroups_julia
