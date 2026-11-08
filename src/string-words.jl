# Copyright (c) 2026, James W. Swent
# Distributed under the terms of the GPL license version 3.
# Prepared with OpenAI Codex for ASCII word interfaces and native adapters.

function _ascii_alphabet(a::AbstractString)
    value = _ascii_string(a)
    length(unique(value)) == length(value) ||
        throw(ArgumentError("an alphabet must not contain duplicate letters"))
    return value
end

"""
    ToWord(alphabet::AbstractString)

Create a callable converter from ASCII strings to 1-based generator positions
in the specified alphabet. An empty alphabet accepts only the empty word.
The converter owns its alphabet; changing a presentation later does not change it.
"""
struct ToWord
    alphabet::String
    positions::Dict{Char,Int}
    function ToWord(alphabet::AbstractString)
        a = _ascii_alphabet(alphabet)
        new(a, Dict(c => i for (i, c) in enumerate(a)))
    end
end

ToWord(p::Presentation{String}) = ToWord(alphabet(p))
alphabet(f::ToWord) = f.alphabet

function (f::ToWord)(word::AbstractString)
    w = _ascii_string(word)
    result = Vector{Int}(undef, length(w))
    for (i, c) in enumerate(w)
        position = Base.get(f.positions, c, 0)
        position != 0 || throw(ArgumentError("letter $(repr(c)) is not in the alphabet"))
        result[i] = position
    end
    return result
end

"""
    ToString(alphabet::AbstractString)

Create a callable converter from 1-based generator positions to ASCII strings.
Positions refer to the supplied alphabet, rather than arbitrary integer labels
in a presentation. An empty alphabet accepts only the empty word.

Use `Iterators.map(ToString("ab"), words)` for a lazy string view of numeric
paths or factorisations. Each produced string owns its storage.
"""
struct ToString
    alphabet::String
    ToString(alphabet::AbstractString) = new(_ascii_alphabet(alphabet))
end

ToString(p::Presentation{String}) = ToString(alphabet(p))
alphabet(f::ToString) = f.alphabet

function (f::ToString)(word::AbstractVector{<:Integer})
    result = Vector{UInt8}(undef, length(word))
    for (i, position) in enumerate(word)
        1 <= position <= ncodeunits(f.alphabet) ||
            throw(ArgumentError("generator position $position is outside the alphabet"))
        result[i] = codeunit(f.alphabet, Int(position))
    end
    return String(result)
end

"""
    StringRange(alphabet="")

A consuming native range of ASCII words, ordered by positions in `alphabet`.
Configure it with `set_min!`, `set_max!`, `set_first!`, `set_last!`, and
`set_order!`, as for `WordRange`. The maximum length is exclusive. Iteration
advances the range, and returns independently owned Julia strings.

Unlike stand-alone string comparisons, the alphabet `"ba"` orders `b` before `a`.
"""
struct StringRange{B}
    cxx_obj::B
end

_native(r::StringRange) = r.cxx_obj
function StringRange(a::AbstractString = "")
    r = StringRange(LibSemigroups.StringRange())
    set_alphabet!(r, a)
    return r
end
StringRange(r::StringRange) = StringRange(LibSemigroups.StringRange(_native(r)))
Base.copy(r::StringRange) = StringRange(r)
Base.deepcopy_internal(r::StringRange, ::IdDict) = Base.copy(r)

function set_alphabet!(r::StringRange, a::AbstractString)
    value = _word_to_cpp(String, _ascii_alphabet(a))
    @wrap_libsemigroups_call LibSemigroups.set_alphabet!(_native(r), value)
    return r
end
alphabet(r::StringRange) = _word_from_cpp(String, LibSemigroups.alphabet(_native(r)))
alphabet_size(r::StringRange) = length(alphabet(r))
Base.get(r::StringRange) =
    _word_from_cpp(String, @wrap_libsemigroups_call LibSemigroups.get(_native(r)))
first_word(r::StringRange) = _word_from_cpp(String, LibSemigroups.first(_native(r)))
last_word(r::StringRange) = _word_from_cpp(String, LibSemigroups.last(_native(r)))
at_end(r::StringRange) = LibSemigroups.at_end(_native(r))
Base.isdone(r::StringRange) = at_end(r)
next!(r::StringRange) = (LibSemigroups.next!(_native(r)); r)
init!(r::StringRange) = (LibSemigroups.init!(_native(r)); r)
AbstractAlgebra.order(r::StringRange) = LibSemigroups.order(_native(r))
upper_bound(r::StringRange) = Int(LibSemigroups.upper_bound(_native(r)))
size_hint(r::StringRange) = LibSemigroups.size_hint(_native(r))
Base.count(r::StringRange) = LibSemigroups.count(_native(r))

function set_order!(r::StringRange, ord::Order)
    @wrap_libsemigroups_call LibSemigroups.set_order!(_native(r), ord)
    return r
end
function set_first!(r::StringRange, word::AbstractString)
    ToWord(alphabet(r))(word)
    w = _word_to_cpp(String, word)
    @wrap_libsemigroups_call LibSemigroups.set_first!(_native(r), w)
    return r
end
function set_last!(r::StringRange, word::AbstractString)
    ToWord(alphabet(r))(word)
    w = _word_to_cpp(String, word)
    @wrap_libsemigroups_call LibSemigroups.set_last!(_native(r), w)
    return r
end
for setter in (:set_min!, :set_max!, :set_upper_bound!)
    @eval function $setter(r::StringRange, n::Integer)
        n >= 0 || throw(ArgumentError("word length must be nonnegative"))
        value = UInt(n)
        @wrap_libsemigroups_call LibSemigroups.$setter(_native(r), value)
        return r
    end
end

Base.IteratorSize(::Type{<:StringRange}) = Base.SizeUnknown()
Base.eltype(::Type{<:StringRange}) = String
function Base.iterate(r::StringRange, state = nothing)
    at_end(r) && return nothing
    word = Base.get(r)
    next!(r)
    return (word, nothing)
end

"""
    random_word(alphabet::AbstractString, length::Integer) -> String

Return a random ASCII word over an explicit alphabet. The empty alphabet can
produce only the empty word.
"""
function random_word(alphabet::AbstractString, n::Integer)
    converter = ToString(alphabet)
    n >= 0 || throw(ArgumentError("word length must be nonnegative"))
    n == 0 && return ""
    isempty(converter.alphabet) &&
        throw(ArgumentError("a nonempty word needs a nonempty alphabet"))
    return converter(random_word(n, length(converter.alphabet)))
end

for (public, native) in (
    (:lex_less, :lexicographical_compare),
    (:shortlex_less, :shortlex_compare),
    (:recursive_path_less, :recursive_path_compare),
)
    @eval function $public(x::AbstractString, y::AbstractString)
        a, b = _word_to_cpp(String, x), _word_to_cpp(String, y)
        return @wrap_libsemigroups_call LibSemigroups.$native(a, b)
    end
end

"""
    weighted_shortlex_less(x::AbstractString, y::AbstractString, weights)
    weighted_lex_less(x::AbstractString, y::AbstractString, weights)

Compare ASCII words using native byte-indexed weights: the weight of character
`c` is `weights[Int(c) + 1]`, including index 1 for NUL. To use alphabet-position
weights instead, convert both words with the same `ToWord` converter and use the
integer-word overload.
"""
function weighted_shortlex_less(
    x::AbstractString,
    y::AbstractString,
    weights::AbstractVector{<:Integer},
)
    a, b = _word_to_cpp(String, x), _word_to_cpp(String, y)
    all(>=(0), weights) || throw(ArgumentError("weights must be nonnegative"))
    native_weights = UInt[UInt(w) for w in weights]
    return @wrap_libsemigroups_call LibSemigroups.wt_shortlex_compare(a, b, native_weights)
end
function weighted_lex_less(
    x::AbstractString,
    y::AbstractString,
    weights::AbstractVector{<:Integer},
)
    a, b = _word_to_cpp(String, x), _word_to_cpp(String, y)
    all(>=(0), weights) || throw(ArgumentError("weights must be nonnegative"))
    native_weights = UInt[UInt(w) for w in weights]
    return @wrap_libsemigroups_call LibSemigroups.wt_lex_compare(a, b, native_weights)
end
