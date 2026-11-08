// Copyright (c) 2026 James W. Swent
// Distributed under the terms of the GPL license version 3.

#ifndef LIBSEMIGROUPS_JULIA_WORD_TRANSPORT_HPP_
#define LIBSEMIGROUPS_JULIA_WORD_TRANSPORT_HPP_

#include "libsemigroups_julia.hpp"

#include <jlcxx/array.hpp>

#include <cstddef>
#include <cstdint>
#include <string>
#include <type_traits>

namespace libsemigroups_julia {

  template <typename Word>
  using WordInput = std::conditional_t<std::is_same_v<Word, std::string>,
                                       std::string const&,
                                       jlcxx::ArrayRef<size_t>>;

  template <typename Word>
  Word native_word(WordInput<Word> input) {
    return Word(input.begin(), input.end());
  }

  template <typename Word>
  using NativeLetter
      = std::conditional_t<std::is_same_v<Word, std::string>, uint8_t, size_t>;

  template <typename Word>
  typename Word::value_type native_letter(NativeLetter<Word> value) {
    return static_cast<typename Word::value_type>(value);
  }

  template <typename Word>
  NativeLetter<Word> bridge_letter(typename Word::value_type value) {
    return static_cast<NativeLetter<Word>>(value);
  }

}  // namespace libsemigroups_julia

#endif  // LIBSEMIGROUPS_JULIA_WORD_TRANSPORT_HPP_
