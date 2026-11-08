# ============================================================================
# Conversions to Congruence
# ============================================================================

"""
    to(::Type{Congruence}, kind::congruence_kind, fp::FroidurePin,
       wg) -> Congruence

Convert a Froidure-Pin graph to a Congruence.

Julia implementation of libsemigroups' `to<Congruence>(kind, fp, wg)`
conversion. `wg` must be either the left or right Cayley graph of `fp`.
The result represents the trivial congruence over the semigroup defined by
`fp`.

`kind` selects whether the resulting congruence is one-sided or two-sided.

# Throws

- [`LibsemigroupsError`](@ref Semigroups.LibsemigroupsError) if `wg` is not
    the left or right Cayley graph of `fp`.
"""
to(::Type{Congruence}, kind::congruence_kind, fp::FroidurePin, wg) = _wrap_graph_congruence(
    @wrap_libsemigroups_call LibSemigroups.to_congruence_from_fpb(kind, fp.cxx_obj, wg)
)

"""
    to(::Type{Congruence}, kind::congruence_kind, wg::WordGraph) -> Congruence

Convert a WordGraph to a Congruence.

Julia implementation of libsemigroups' `to<Congruence>(kind, wg)`
conversion. The result represents the trivial congruence over `wg`.

`kind` selects whether the resulting congruence is one-sided or two-sided.

The graph is added to the constructed congruence as-is; no checks are made
that the resulting Todd-Coxeter or Congruence object is valid.
"""
@cxxdereference to(::Type{Congruence}, kind::congruence_kind, wg::WordGraph) =
    _wrap_graph_congruence(
        @wrap_libsemigroups_call LibSemigroups.to_congruence_from_wg(kind, wg)
    )

# ============================================================================
# Conversions to ToddCoxeter
# ============================================================================

"""
    to(::Type{ToddCoxeter}, kind::congruence_kind, fp::FroidurePin,
       wg::WordGraph) -> ToddCoxeter

Convert a Froidure-Pin graph to a Todd-Coxeter.

Julia implementation of libsemigroups' `to<ToddCoxeter>(kind, fp, wg)`
conversion. `wg` must be either the left or right Cayley graph of `fp`.
The result represents the trivial congruence over the semigroup defined by
`fp`.
`kind` selects whether the resulting congruence is one-sided or two-sided.

# Throws

- [`LibsemigroupsError`](@ref Semigroups.LibsemigroupsError) if `wg` is not
    the left or right Cayley graph of `fp`.
"""
to(::Type{ToddCoxeter}, kind::congruence_kind, fp::FroidurePin, wg) = _wrap_todd_coxeter(
    @wrap_libsemigroups_call LibSemigroups.to_todd_coxeter_from_fpb(kind, fp.cxx_obj, wg)
)

"""
    to(::Type{ToddCoxeter}, kind::congruence_kind, kb::KnuthBendix) -> ToddCoxeter

Convert a Knuth-Bendix to a Todd-Coxeter.

Julia implementation of libsemigroups' `to<ToddCoxeter>(kind, kb)`
conversion. It uses the right Cayley graph of the semigroup represented by
`kb` and returns the corresponding trivial congruence.
`kind` selects whether the resulting congruence is one-sided or two-sided.

# Throws

- [`LibsemigroupsError`](@ref Semigroups.LibsemigroupsError) if `kb` does not
    represent a two-sided congruence or has infinitely many classes. In the
    infinite case, use `ToddCoxeter(kind, presentation(kb))` instead.
"""
to(::Type{ToddCoxeter}, kind::congruence_kind, kb::KnuthBendix{W}) where {W} =
    to(ToddCoxeter{W}, kind, kb)

# ============================================================================
# Conversions to Presentation
# ============================================================================

"""
    to(::Type{Presentation}, p::Presentation) -> Presentation

Julia implementation of the identity conversion for `Presentation`. The
returned presentation is a copy of `p`.
"""
to(::Type{Presentation}, p::Presentation) = Presentation(p)

"""
    to(::Type{Presentation}, c::Congruence) -> Presentation

Julia implementation of libsemigroups' `to<Presentation>(c)` conversion.
Return the presentation used to construct or initialise `c`.

This conversion returns the presentation used to construct or initialise `c`.
Congruence-generating pairs are not added to the returned presentation by
running `c`.
"""
to(::Type{Presentation}, c::Congruence{W}) where {W} = to(Presentation{W}, c)

"""
    to(::Type{Presentation}, k::Kambites) -> Presentation

Julia implementation of libsemigroups' `to<Presentation>(k)` conversion.
Return a presentation equivalent to the presentation used to construct or
initialise `k`.

This conversion does not enumerate `k`.
"""
to(::Type{Presentation}, k::Kambites{W}) where {W} = to(Presentation{W}, k)

"""
    to(::Type{Presentation}, tc::ToddCoxeter) -> Presentation

Julia implementation of libsemigroups' `to<Presentation>(tc)` conversion.
Return the presentation used to construct or initialise `tc`.

This conversion does not enumerate `tc`.
"""
to(::Type{Presentation}, tc::ToddCoxeter{W}) where {W} = to(Presentation{W}, tc)

"""
    to(::Type{Presentation}, kb::KnuthBendix) -> Presentation

Julia implementation of libsemigroups' `to<Presentation>(kb)` conversion.
Return a presentation using the currently active rules of `kb`.

This conversion does not enumerate `kb`, so the returned presentation may not
yet describe the completed semigroup or monoid. Run `kb` first if a fully
processed presentation is required.
"""
to(::Type{Presentation}, kb::KnuthBendix{W}) where {W} = to(Presentation{W}, kb)

"""
    to(::Type{Presentation}, fp::FroidurePin) -> Presentation

Julia implementation of libsemigroups' `to<Presentation>(fp)` conversion.
Return a presentation using the currently known rules of `fp`.

This conversion enumerates `fp` before obtaining its presentation.
"""
to(::Type{Presentation}, fp::FroidurePin) = to(Presentation{Vector{Int}}, fp)

# ============================================================================
# Conversions to KnuthBendix
# ============================================================================

"""
    to(::Type{KnuthBendix}, kind::congruence_kind, fp::FroidurePin) -> KnuthBendix

Julia implementation of libsemigroups' `to<KnuthBendix>(kind, fp)`
conversion. It constructs a Knuth-Bendix instance from the presentation
obtained from `fp` and represents the trivial congruence over that semigroup.
`kind` selects whether the resulting congruence is one-sided or two-sided.

This conversion enumerates `fp` before obtaining its presentation.
"""
to(::Type{KnuthBendix}, kind::congruence_kind, fp::FroidurePin) = _wrap_knuth_bendix(
    @wrap_libsemigroups_call LibSemigroups.to_knuth_bendix_from_fpb(kind, fp.cxx_obj)
)

"""
    to(::Type{KnuthBendix}, kind::congruence_kind, tc::ToddCoxeter) -> KnuthBendix

Julia implementation of libsemigroups' `to<KnuthBendix>(kind, tc)`
conversion. It constructs a Knuth-Bendix instance from `tc.presentation()`
and represents the trivial congruence over the semigroup defined by `tc`.
`kind` selects whether the resulting congruence is one-sided or two-sided.
"""
to(::Type{KnuthBendix}, kind::congruence_kind, tc::ToddCoxeter{W}) where {W} =
    to(KnuthBendix{W}, kind, tc)

# ============================================================================
# Conversions to FroidurePin
# ============================================================================

"""
    to(::Type{FroidurePin}, wg::WordGraph) -> FroidurePin{Transf{UInt32}}

Convert a complete `WordGraph` to a Froidure-Pin whose elements are
`Transf{UInt32}`. This is the Julia implementation of
libsemigroups' `to<FroidurePin>(wg)` conversion. Each graph label becomes a
transformation generator, with the transformation image determined by the
edge target for each node.

The graph must be complete, and every target must be a node of the graph.

# Throws

- [`LibsemigroupsError`](@ref Semigroups.LibsemigroupsError) if the graph is
    incomplete or contains an out-of-range target.
"""
@cxxdereference to(::Type{FroidurePin}, wg::WordGraph) =
    FroidurePin{Transf{UInt32}}(@wrap_libsemigroups_call begin
        LibSemigroups.to_froidure_pin_from_wg(wg)
    end)

# ============================================================================
# Conversions to InversePresentation
# ============================================================================

"""
    to(::Type{InversePresentation}, p::Presentation) -> InversePresentation

Convert a Presentation to an InversePresentation.

Julia implementation of libsemigroups' `to<InversePresentation>(p)`
conversion. The resulting inverse presentation has rules equivalent to
those of `p`, over a normalised alphabet with a corresponding inverse
letter for each letter of `p`.
"""
to(::Type{InversePresentation}, p::Presentation{W}) where {W} =
    to(InversePresentation{W}, p)

"""
    to(::Type{InversePresentation}, ip::InversePresentation) -> InversePresentation

Convert an InversePresentation to an InversePresentation.

Return a copy of `ip`.
"""
to(::Type{InversePresentation}, ip::InversePresentation) = InversePresentation(ip)


_native(fp::FroidurePin) = fp.cxx_obj
_word_type(::FroidurePin) = Vector{Int}

_to_presentation_native(::Type{Vector{Int}}, x) = LibSemigroups.to_presentation_word(x)
_to_presentation_native(::Type{String}, x) = LibSemigroups.to_presentation_string(x)
_to_inverse_native(::Type{Vector{Int}}, x) = LibSemigroups.to_inverse_presentation_word(x)
_to_inverse_native(::Type{String}, x) = LibSemigroups.to_inverse_presentation_string(x)

"""
    to(Presentation{W}, source; alphabet=nothing)

Construct an owning presentation with word representation `W` (`String` or
`Vector{Int}`). A change of representation uses native default generator labels;
provide `alphabet` to choose the target labels explicitly, in source alphabet
order. This relabels words, rather than parsing or formatting expressions.
String alphabets and words must be ASCII. The empty-word flag is preserved.
"""
function to(
    ::Type{Presentation{W}},
    source::Union{Presentation,CongruenceCommon,FroidurePin};
    alphabet = nothing,
) where {W}
    W in (String, Vector{Int}) || throw(ArgumentError("unsupported word representation $W"))
    target_alphabet =
        alphabet === nothing ? nothing : _word_from_cpp(W, _word_to_cpp(W, alphabet))
    if target_alphabet !== nothing
        length(unique(target_alphabet)) == length(target_alphabet) ||
            throw(ArgumentError("an alphabet must not contain duplicate letters"))
    end
    if W === String || target_alphabet !== nothing
        n =
            source isa FroidurePin ? number_of_generators(source) :
            length(
                Semigroups.alphabet(
                    source isa Presentation ? source : presentation(source),
                ),
            )
        W === String &&
            n > 128 &&
            throw(ArgumentError("an ASCII presentation supports at most 128 generators"))
        target_alphabet !== nothing &&
            length(target_alphabet) != n &&
            throw(ArgumentError("the target alphabet must have $n letters"))
    end
    # An explicit alphabet is not constrained by the native FroidurePin-to-string
    # conversion's consecutive-byte default. Translate the numeric presentation
    # through alphabet positions instead, after validating the requested labels.
    if W === String && source isa FroidurePin && target_alphabet !== nothing
        numeric = to(Presentation{Vector{Int}}, source)
        return to(Presentation{String}, numeric; alphabet = target_alphabet)
    end
    native = @wrap_libsemigroups_call _to_presentation_native(W, _native(source))
    result = _wrap_presentation(native)
    target_alphabet === nothing || change_alphabet!(result, target_alphabet)
    return result
end

function to(::Type{InversePresentation{W}}, p::Presentation) where {W}
    q = _word_type(p) === W ? p : to(Presentation{W}, p)
    if W === String && !(p isa InversePresentation)
        length(alphabet(q)) <= 15 || throw(
            ArgumentError(
                "libsemigroups 3.6.1 generates a non-ASCII inverse alphabet above 15 generators",
            ),
        )
    end
    return _wrap_presentation(@wrap_libsemigroups_call _to_inverse_native(W, _native(q)))
end

function to(::Type{InversePresentation{W}}, p::InversePresentation) where {W}
    W === String &&
        length(alphabet(p)) > 128 &&
        throw(ArgumentError("an ASCII presentation supports at most 128 generators"))
    return _wrap_presentation(@wrap_libsemigroups_call _to_inverse_native(W, _native(p)))
end

# Native conversion names encode the target representation; source types dispatch
# through CxxWrap. The unspecialized public conversions preserve their source's
# representation, while graph-only conversions default to integer words.
function to(::Type{ToddCoxeter{W}}, kind::congruence_kind, kb::KnuthBendix) where {W}
    f =
        W === String ? LibSemigroups.to_todd_coxeter_from_kb_string :
        W === Vector{Int} ? LibSemigroups.to_todd_coxeter_from_kb :
        throw(ArgumentError("unsupported word representation $W"))
    return _wrap_todd_coxeter(@wrap_libsemigroups_call f(kind, _native(kb)))
end

function to(::Type{KnuthBendix{W}}, kind::congruence_kind, tc::ToddCoxeter) where {W}
    f =
        W === String ? LibSemigroups.to_knuth_bendix_from_tc_string :
        W === Vector{Int} ? LibSemigroups.to_knuth_bendix_from_tc :
        throw(ArgumentError("unsupported word representation $W"))
    return _wrap_knuth_bendix(@wrap_libsemigroups_call f(kind, _native(tc)))
end

function to(::Type{KnuthBendix{W}}, kind::congruence_kind, fp::FroidurePin) where {W}
    p = to(Presentation{W}, fp)
    return KnuthBendix(kind, p)
end

function to(::Type{ToddCoxeter{W}}, kind::congruence_kind, fp::FroidurePin, wg) where {W}
    f =
        W === String ? LibSemigroups.to_todd_coxeter_from_fpb_string :
        W === Vector{Int} ? LibSemigroups.to_todd_coxeter_from_fpb :
        throw(ArgumentError("unsupported word representation $W"))
    return _wrap_todd_coxeter(@wrap_libsemigroups_call f(kind, _native(fp), wg))
end

function to(::Type{Congruence{W}}, kind::congruence_kind, fp::FroidurePin, wg) where {W}
    f =
        W === String ? LibSemigroups.to_congruence_from_fpb_string :
        W === Vector{Int} ? LibSemigroups.to_congruence_from_fpb :
        throw(ArgumentError("unsupported word representation $W"))
    return _wrap_graph_congruence(@wrap_libsemigroups_call f(kind, _native(fp), wg))
end

function to(
    ::Type{Congruence{W}},
    kind::congruence_kind,
    wg::Union{WordGraph,CxxWrap.CxxBaseRef{WordGraph}},
) where {W}
    f =
        W === String ? LibSemigroups.to_congruence_from_wg_string :
        W === Vector{Int} ? LibSemigroups.to_congruence_from_wg :
        throw(ArgumentError("unsupported word representation $W"))
    return _wrap_graph_congruence(@wrap_libsemigroups_call f(kind, wg))
end
