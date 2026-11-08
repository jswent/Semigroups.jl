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

#include <libsemigroups/order.hpp>
#include <libsemigroups/types.hpp>
#include <libsemigroups/word-range.hpp>

#include <jlcxx/array.hpp>

#include <cstdint>
#include <string>
#include <type_traits>
#include <vector>

namespace jlcxx {
  template <>
  struct IsMirroredType<libsemigroups::WordRange> : std::false_type {};

  template <>
  struct IsMirroredType<libsemigroups::StringRange> : std::false_type {};
}  // namespace jlcxx

namespace libsemigroups_julia {

  template <typename Range, typename Word>
  void define_word_range_type(jl::Module& m, char const* name) {
    using libsemigroups::Order;

    auto type = m.add_type<Range>(name);

    type.template constructor<>();
    type.template constructor<Range const&>();

    //////////////////////////////////////////////////////////////////////////
    // Iteration protocol
    //////////////////////////////////////////////////////////////////////////

    type.method("get", [](Range const& self) -> Word { return self.get(); });
    type.method("next!", [](Range& self) { self.next(); });
    type.method("at_end",
                [](Range const& self) -> bool { return self.at_end(); });
    type.method("size_hint",
                [](Range const& self) -> uint64_t { return self.size_hint(); });
    type.method("count",
                [](Range const& self) -> uint64_t { return self.count(); });
    if constexpr (std::is_same_v<Range, libsemigroups::WordRange>) {
      type.method("valid",
                  [](Range const& self) -> bool { return self.valid(); });
    }
    type.method("init!", [](Range& self) -> Range& { return self.init(); });

    //////////////////////////////////////////////////////////////////////////
    // Getter/setter pairs — split names to avoid CxxWrap overload issues
    //////////////////////////////////////////////////////////////////////////

    if constexpr (std::is_same_v<Range, libsemigroups::WordRange>) {
      type.method("alphabet_size", [](Range const& self) -> size_t {
        return self.alphabet_size();
      });
      type.method("set_alphabet_size!",
                  [](Range& self, size_t n) { self.alphabet_size(n); });
    } else {
      type.method("alphabet", [](Range const& self) -> std::string {
        return self.alphabet();
      });
      type.method("set_alphabet!",
                  [](Range& self, std::string const& alphabet) {
                    self.alphabet(alphabet);
                  });
    }

    type.method("first",
                [](Range const& self) -> Word { return self.first(); });
    type.method("set_first!", [](Range& self, WordInput<Word> w) {
      self.first(native_word<Word>(w));
    });

    type.method("last", [](Range const& self) -> Word { return self.last(); });
    type.method("set_last!", [](Range& self, WordInput<Word> w) {
      self.last(native_word<Word>(w));
    });

    type.method("order", [](Range const& self) { return self.order(); });
    type.method("set_order!", [](Range& self, Order o) { self.order(o); });

    type.method("upper_bound",
                [](Range const& self) -> size_t { return self.upper_bound(); });
    type.method("set_upper_bound!",
                [](Range& self, size_t n) { self.upper_bound(n); });

    // min / max are setter-only upstream (they set first/last to word_type(val,
    // 0)).
    type.method("set_min!", [](Range& self, size_t n) { self.min(n); });
    type.method("set_max!", [](Range& self, size_t n) { self.max(n); });
  }

  void define_word_range(jl::Module& m) {
    using libsemigroups::word_type;
    define_word_range_type<libsemigroups::WordRange, word_type>(m, "WordRange");
    define_word_range_type<libsemigroups::StringRange, std::string>(
        m, "StringRange");
    m.method("number_of_words",
             [](size_t n, size_t min, size_t max) -> uint64_t {
               return libsemigroups::number_of_words(n, min, max);
             });
    m.method("random_word", [](size_t length, size_t nr_letters) -> word_type {
      return libsemigroups::random_word(length, nr_letters);
    });
  }

}  // namespace libsemigroups_julia
