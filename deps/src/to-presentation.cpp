#include "libsemigroups_julia.hpp"
#include "presentation-conversion.hpp"

#include <libsemigroups/bmat8.hpp>
#include <libsemigroups/cong-class.hpp>
#include <libsemigroups/froidure-pin.hpp>
#include <libsemigroups/kambites-class.hpp>
#include <libsemigroups/knuth-bendix-class.hpp>
#include <libsemigroups/presentation.hpp>
#include <libsemigroups/to-presentation.hpp>
#include <libsemigroups/todd-coxeter-class.hpp>
#include <libsemigroups/transf.hpp>
#include <libsemigroups/types.hpp>

namespace libsemigroups_julia {
  namespace {
    template <typename Word, typename Source>
    void define_algorithm_to_presentation(jl::Module& m, char const* name) {
      m.method(name, [](Source& self) -> libsemigroups::Presentation<Word> {
        auto result
            = libsemigroups::to<libsemigroups::Presentation<Word>>(self);
        check_presentation_alphabet(result);
        return result;
      });
    }

    template <typename Word, typename SourceWord>
    void define_presentation_conversions(jl::Module& m,
                                         char const* name,
                                         char const* inverse_name) {
      using P        = libsemigroups::Presentation<Word>;
      using SourceP  = libsemigroups::Presentation<SourceWord>;
      using IP       = libsemigroups::InversePresentation<Word>;
      using SourceIP = libsemigroups::InversePresentation<SourceWord>;
      m.method(name, [](SourceP const& p) -> P {
        return convert_presentation<Word>(p);
      });
      m.method(inverse_name, [](SourceP const& p) -> IP {
        // v3.6.1 constructs the doubled alphabet consecutively from 'a'.
        if constexpr (std::is_same_v<Word, std::string>) {
          if (p.alphabet().size() > 15) {
            throw std::invalid_argument(
                "native string inverse-presentation conversion supports at "
                "most 15 source letters; convert the integer inverse "
                "presentation with an explicit alphabet instead");
          }
        }
        auto converted = convert_presentation<Word>(p);
        IP   result = libsemigroups::v4::to<libsemigroups::InversePresentation>(
            converted);
        check_presentation_alphabet(result);
        return result;
      });
      m.method(inverse_name, [](SourceIP const& p) -> IP {
        if constexpr (std::is_same_v<Word, SourceWord>) {
          check_presentation_alphabet(p);
          return IP(p);
        } else {
          if constexpr (std::is_same_v<Word, std::string>) {
            if (p.alphabet().size() > 128) {
              throw std::invalid_argument(
                  "a string presentation supports at most 128 ASCII letters");
            }
          }
          // The one-argument cross-type overload is incorrectly noexcept in
          // v3.6.1. Its checked callback overload safely transports failures.
          IP result = libsemigroups::v4::to<IP>(p, [&p](auto letter) {
            return libsemigroups::words::human_readable_letter<Word>(
                p.index(letter));
          });
          check_presentation_alphabet(result);
          return result;
        }
      });
      define_algorithm_to_presentation<Word,
                                       libsemigroups::Congruence<SourceWord>>(
          m, name);
      define_algorithm_to_presentation<Word,
                                       libsemigroups::Kambites<SourceWord>>(
          m, name);
      define_algorithm_to_presentation<Word,
                                       libsemigroups::ToddCoxeter<SourceWord>>(
          m, name);
      define_algorithm_to_presentation<Word,
                                       libsemigroups::KnuthBendix<SourceWord>>(
          m, name);
    }

    template <typename Word, typename E>
    void define_froidure_pin_to_presentation(jl::Module& m, char const* name) {
      m.method(name,
               [](libsemigroups::FroidurePin<E>& fp)
                   -> libsemigroups::Presentation<Word> {
                 return froidure_pin_presentation<Word>(fp);
               });
    }

    template <typename Word>
    void define_target_presentation(jl::Module& m,
                                    char const* name,
                                    char const* inverse_name) {
      define_presentation_conversions<Word, libsemigroups::word_type>(
          m, name, inverse_name);
      define_presentation_conversions<Word, std::string>(m, name, inverse_name);
      define_froidure_pin_to_presentation<Word,
                                          libsemigroups::Transf<0, uint8_t>>(
          m, name);
      define_froidure_pin_to_presentation<Word,
                                          libsemigroups::Transf<0, uint16_t>>(
          m, name);
      define_froidure_pin_to_presentation<Word,
                                          libsemigroups::Transf<0, uint32_t>>(
          m, name);
      define_froidure_pin_to_presentation<Word,
                                          libsemigroups::PPerm<0, uint8_t>>(
          m, name);
      define_froidure_pin_to_presentation<Word,
                                          libsemigroups::PPerm<0, uint16_t>>(
          m, name);
      define_froidure_pin_to_presentation<Word,
                                          libsemigroups::PPerm<0, uint32_t>>(
          m, name);
      define_froidure_pin_to_presentation<Word,
                                          libsemigroups::Perm<0, uint8_t>>(
          m, name);
      define_froidure_pin_to_presentation<Word,
                                          libsemigroups::Perm<0, uint16_t>>(
          m, name);
      define_froidure_pin_to_presentation<Word,
                                          libsemigroups::Perm<0, uint32_t>>(
          m, name);
      define_froidure_pin_to_presentation<Word, libsemigroups::BMat8>(m, name);
    }
  }  // namespace

  void define_to_presentation(jl::Module& m) {
    define_target_presentation<libsemigroups::word_type>(
        m, "to_presentation_word", "to_inverse_presentation_word");
    define_target_presentation<std::string>(
        m, "to_presentation_string", "to_inverse_presentation_string");
  }
}  // namespace libsemigroups_julia
