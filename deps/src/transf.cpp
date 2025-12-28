// transf.cpp - Transformation bindings for libsemigroups_julia
//
// This file exposes libsemigroups transformation classes (Transf, PPerm, Perm)
// to Julia via CxxWrap. It binds concrete template instantiations for
// uint8_t, uint16_t, and uint32_t scalar types.
//
// This implementation mirrors the Python bindings in libsemigroups_pybind11.

#include "libsemigroups_julia.hpp"
#include <libsemigroups/transf.hpp>

namespace libsemigroups_julia {

namespace {

template <typename PTransfType>
void bind_ptransf_common(jl::Module &                      m,
                         jlcxx::TypeWrapper<PTransfType> & type,
                         std::string const &               type_name)
{
  using Scalar = typename PTransfType::point_type;

  ////////////////////////////////////////////////////////////////////////
  // Constructor
  ////////////////////////////////////////////////////////////////////////

  // Safe constructor using make<> which validates inputs
  m.method(type_name, [](std::vector<Scalar> const & imgs) -> PTransfType {
    return libsemigroups::make<PTransfType>(imgs);
  });

  ////////////////////////////////////////////////////////////////////////
  // Special methods (Python __xxx__ equivalents)
  ////////////////////////////////////////////////////////////////////////

  // copy / __copy__ - explicit copy constructor
  type.method("copy", [](PTransfType const & self) {
    return PTransfType(self);
  });

  // __getitem__ equivalent - element access with bounds checking
  type.method("getindex", [](PTransfType const & self, size_t i) -> Scalar {
    return self.at(i);
  });

  // __hash__ equivalent
  type.method("hash", &PTransfType::hash_value);

  ////////////////////////////////////////////////////////////////////////
  // Instance methods
  ////////////////////////////////////////////////////////////////////////

  type.method("degree", &PTransfType::degree);
  type.method("rank", &PTransfType::rank);

  // swap - use lambda to avoid exposing PTransfBase in signature
  type.method("swap", [](PTransfType & self, PTransfType & other) {
    self.swap(other);
  });

  // increase_degree_by - modifies in place, don't expose base class return type
  type.method("increase_degree_by!", [](PTransfType & self, size_t m) {
    self.increase_degree_by(m);
  });

  // images - return a Julia-compatible iterator (we use a vector)
  type.method("images_vector", [](PTransfType const & self) {
    std::vector<Scalar> result;
    result.reserve(self.degree());
    for (auto val : self)
    {
      result.push_back(val);
    }
    return result;
  });

  ////////////////////////////////////////////////////////////////////////
  // Static methods
  ////////////////////////////////////////////////////////////////////////

  // one(n) - static method that creates identity of degree n
  m.method("one", [](jlcxx::SingletonType<PTransfType>, size_t n) {
    return PTransfType::one(n);
  });

  ////////////////////////////////////////////////////////////////////////
  // Comparison operators
  ////////////////////////////////////////////////////////////////////////

  // NOTE: We use named functions as CxxWrap doesn't properly bind
  // operator symbols as Julia-callable methods

  type.method("is_equal", [](PTransfType const & a, PTransfType const & b) -> bool {
    return a == b;
  });

  type.method("is_not_equal", [](PTransfType const & a, PTransfType const & b) -> bool {
    return a != b;
  });

  type.method("is_less", [](PTransfType const & a, PTransfType const & b) -> bool {
    return a < b;
  });

  type.method("is_less_equal", [](PTransfType const & a, PTransfType const & b) -> bool {
    return a <= b;
  });

  type.method("is_greater", [](PTransfType const & a, PTransfType const & b) -> bool {
    return a > b;
  });

  type.method("is_greater_equal",
              [](PTransfType const & a, PTransfType const & b) -> bool {
                return a >= b;
              });

  type.method("multiply", [](PTransfType const & a, PTransfType const & b) {
    return a * b;
  });

  m.method("product_inplace!",
           [](PTransfType & xy, PTransfType const & x, PTransfType const & y) {
    xy.product_inplace(x, y);
  });
}

template <typename TransfType>
void bind_transf_type(jl::Module & m, std::string const & name)
{
  auto type = m.add_type<TransfType>(name);
  bind_ptransf_common(m, type, name);
}

template <typename PPermType>
void bind_pperm_type(jl::Module & m, std::string const & name)
{
  using Scalar = typename PPermType::point_type;

  auto type = m.add_type<PPermType>(name);
  bind_ptransf_common(m, type, name);

  // Constructor from domain, image, and degree using make<>
  m.method(name,
           [](std::vector<Scalar> const & dom, std::vector<Scalar> const & img,
              size_t deg) -> PPermType {
             return libsemigroups::make<PPermType>(dom, img, deg);
           });
}

template <typename PermType> void bind_perm_type(jl::Module & m, std::string const & name)
{
  auto type = m.add_type<PermType>(name);
  bind_ptransf_common(m, type, name);
}

}    // anonymous namespace

// Main function to define all transformation bindings
void define_transf(jl::Module & m)
{
  using namespace libsemigroups;

  ////////////////////////////////////////////////////////////////////////
  // Bind concrete instantiations: Transf
  ////////////////////////////////////////////////////////////////////////

  bind_transf_type<Transf<0, uint8_t>>(m, "Transf1");
  bind_transf_type<Transf<0, uint16_t>>(m, "Transf2");
  bind_transf_type<Transf<0, uint32_t>>(m, "Transf4");

  ////////////////////////////////////////////////////////////////////////
  // Bind concrete instantiations: PPerm
  ////////////////////////////////////////////////////////////////////////

  bind_pperm_type<PPerm<0, uint8_t>>(m, "PPerm1");
  bind_pperm_type<PPerm<0, uint16_t>>(m, "PPerm2");
  bind_pperm_type<PPerm<0, uint32_t>>(m, "PPerm4");

  ////////////////////////////////////////////////////////////////////////
  // Bind concrete instantiations: Perm
  ////////////////////////////////////////////////////////////////////////

  bind_perm_type<Perm<0, uint8_t>>(m, "Perm1");
  bind_perm_type<Perm<0, uint16_t>>(m, "Perm2");
  bind_perm_type<Perm<0, uint32_t>>(m, "Perm4");

  ////////////////////////////////////////////////////////////////////////
  // Module-level helper functions: one
  ////////////////////////////////////////////////////////////////////////

  // one(f) - returns identity of same degree as f
  m.method("one", [](Transf<0, uint8_t> const & f) {
    return libsemigroups::one(f);
  });
  m.method("one", [](Transf<0, uint16_t> const & f) {
    return libsemigroups::one(f);
  });
  m.method("one", [](Transf<0, uint32_t> const & f) {
    return libsemigroups::one(f);
  });

  m.method("one", [](PPerm<0, uint8_t> const & f) {
    return libsemigroups::one(f);
  });
  m.method("one", [](PPerm<0, uint16_t> const & f) {
    return libsemigroups::one(f);
  });
  m.method("one", [](PPerm<0, uint32_t> const & f) {
    return libsemigroups::one(f);
  });

  m.method("one", [](Perm<0, uint8_t> const & f) {
    return libsemigroups::one(f);
  });
  m.method("one", [](Perm<0, uint16_t> const & f) {
    return libsemigroups::one(f);
  });
  m.method("one", [](Perm<0, uint32_t> const & f) {
    return libsemigroups::one(f);
  });

  ////////////////////////////////////////////////////////////////////////
  // Module-level helper functions: image
  ////////////////////////////////////////////////////////////////////////

  // image(f) - returns sorted vector of image points (excluding UNDEFINED)
  m.method("image", [](Transf<0, uint8_t> const & f) {
    return libsemigroups::image(f);
  });
  m.method("image", [](Transf<0, uint16_t> const & f) {
    return libsemigroups::image(f);
  });
  m.method("image", [](Transf<0, uint32_t> const & f) {
    return libsemigroups::image(f);
  });

  m.method("image", [](PPerm<0, uint8_t> const & f) {
    return libsemigroups::image(f);
  });
  m.method("image", [](PPerm<0, uint16_t> const & f) {
    return libsemigroups::image(f);
  });
  m.method("image", [](PPerm<0, uint32_t> const & f) {
    return libsemigroups::image(f);
  });

  m.method("image", [](Perm<0, uint8_t> const & f) {
    return libsemigroups::image(f);
  });
  m.method("image", [](Perm<0, uint16_t> const & f) {
    return libsemigroups::image(f);
  });
  m.method("image", [](Perm<0, uint32_t> const & f) {
    return libsemigroups::image(f);
  });

  ////////////////////////////////////////////////////////////////////////
  // Module-level helper functions: domain
  ////////////////////////////////////////////////////////////////////////

  // domain(f) - returns sorted vector of domain points (where f is defined)
  m.method("domain", [](Transf<0, uint8_t> const & f) {
    return libsemigroups::domain(f);
  });
  m.method("domain", [](Transf<0, uint16_t> const & f) {
    return libsemigroups::domain(f);
  });
  m.method("domain", [](Transf<0, uint32_t> const & f) {
    return libsemigroups::domain(f);
  });

  m.method("domain", [](PPerm<0, uint8_t> const & f) {
    return libsemigroups::domain(f);
  });
  m.method("domain", [](PPerm<0, uint16_t> const & f) {
    return libsemigroups::domain(f);
  });
  m.method("domain", [](PPerm<0, uint32_t> const & f) {
    return libsemigroups::domain(f);
  });

  m.method("domain", [](Perm<0, uint8_t> const & f) {
    return libsemigroups::domain(f);
  });
  m.method("domain", [](Perm<0, uint16_t> const & f) {
    return libsemigroups::domain(f);
  });
  m.method("domain", [](Perm<0, uint32_t> const & f) {
    return libsemigroups::domain(f);
  });

  ////////////////////////////////////////////////////////////////////////
  // Module-level helper functions: inverse (PPerm and Perm only)
  ////////////////////////////////////////////////////////////////////////

  // inverse(f) - returns inverse partial perm or perm
  m.method("inverse", [](PPerm<0, uint8_t> const & f) {
    return libsemigroups::inverse(f);
  });
  m.method("inverse", [](PPerm<0, uint16_t> const & f) {
    return libsemigroups::inverse(f);
  });
  m.method("inverse", [](PPerm<0, uint32_t> const & f) {
    return libsemigroups::inverse(f);
  });

  m.method("inverse", [](Perm<0, uint8_t> const & f) {
    return libsemigroups::inverse(f);
  });
  m.method("inverse", [](Perm<0, uint16_t> const & f) {
    return libsemigroups::inverse(f);
  });
  m.method("inverse", [](Perm<0, uint32_t> const & f) {
    return libsemigroups::inverse(f);
  });

  ////////////////////////////////////////////////////////////////////////
  // Module-level helper functions: left_one and right_one (PPerm only)
  ////////////////////////////////////////////////////////////////////////

  // left_one(f) - partial perm that fixes domain points
  m.method("left_one", [](PPerm<0, uint8_t> const & f) {
    return libsemigroups::left_one(f);
  });
  m.method("left_one", [](PPerm<0, uint16_t> const & f) {
    return libsemigroups::left_one(f);
  });
  m.method("left_one", [](PPerm<0, uint32_t> const & f) {
    return libsemigroups::left_one(f);
  });

  // right_one(f) - partial perm that fixes image points
  m.method("right_one", [](PPerm<0, uint8_t> const & f) {
    return libsemigroups::right_one(f);
  });
  m.method("right_one", [](PPerm<0, uint16_t> const & f) {
    return libsemigroups::right_one(f);
  });
  m.method("right_one", [](PPerm<0, uint32_t> const & f) {
    return libsemigroups::right_one(f);
  });
}

}    // namespace libsemigroups_julia
