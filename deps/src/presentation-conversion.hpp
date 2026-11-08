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

#ifndef SEMIGROUPS_JULIA_PRESENTATION_CONVERSION_HPP_
#define SEMIGROUPS_JULIA_PRESENTATION_CONVERSION_HPP_

#include "libsemigroups_julia.hpp"

#include <libsemigroups/froidure-pin-base.hpp>
#include <libsemigroups/presentation.hpp>
#include <libsemigroups/to-presentation.hpp>

#include <stdexcept>
#include <string>
#include <type_traits>

namespace libsemigroups_julia {
  // Conversions can create letters even when their inputs are numeric. Check
  // the resulting alphabet before exposing it through the ASCII string API.
  template <typename Word>
  void check_presentation_alphabet(libsemigroups::Presentation<Word> const& p) {
    if constexpr (std::is_same_v<Word, std::string>) {
      for (unsigned char c : p.alphabet()) {
        if (c > 127) {
          throw std::invalid_argument(
              "the converted presentation has non-ASCII letters");
        }
      }
    }
  }

  template <typename Word, typename SourceWord>
  libsemigroups::Presentation<Word>
  convert_presentation(libsemigroups::Presentation<SourceWord> const& p) {
    using Result = libsemigroups::Presentation<Word>;
    if constexpr (std::is_same_v<Word, std::string>) {
      if (p.alphabet().size() > 128) {
        throw std::invalid_argument(
            "a string presentation supports at most 128 ASCII letters");
      }
    }
    Result result = libsemigroups::v4::to<Result>(p);
    check_presentation_alphabet(result);
    return result;
  }

  template <typename Word>
  libsemigroups::Presentation<Word>
  froidure_pin_presentation(libsemigroups::FroidurePinBase& fp) {
    if constexpr (std::is_same_v<Word, std::string>) {
      if (fp.number_of_generators() > 128) {
        throw std::invalid_argument(
            "a string presentation supports at most 128 ASCII letters");
      }
    }
    // The v3.6.1 direct string conversion labels its alphabet consecutively
    // from 'a', but labels rule letters with human_readable_letter. These
    // disagree beyond 26 generators. Convert one consistent numeric
    // presentation instead, so the same bijection maps alphabet and rules.
    auto numeric = libsemigroups::to<
        libsemigroups::Presentation<libsemigroups::word_type>>(fp);
    if constexpr (std::is_same_v<Word, libsemigroups::word_type>) {
      return numeric;
    } else {
      return convert_presentation<Word>(numeric);
    }
  }
}  // namespace libsemigroups_julia

#endif
