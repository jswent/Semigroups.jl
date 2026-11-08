# Copyright (c) 2026, James W. Swent
#
# Distributed under the terms of the GPL license version 3.
# Prepared with OpenAI Codex for word representation and binding adapters.

using CxxWrap.StdLib: StdString, StdVector

# Public words have one of two representations. Native graph labels and
# numeric words remain zero-based; string letters are literal ASCII bytes.
const _WordInput = Union{AbstractVector{<:Integer},AbstractString}
const _LetterInput = Union{Integer,AbstractChar}

_native(x) = x

@inline function _letter_to_cpp(i::Integer)
    1 <= i <= typemax(Int) || throw(InexactError(:_letter_to_cpp, Int, i))
    return UInt(i) - UInt(1)
end

@inline function _letter_from_cpp(x::Integer)
    0 <= x < typemax(Int) || throw(InexactError(:_letter_from_cpp, Int, x))
    return Int(x) + 1
end

_word_to_cpp(v::AbstractVector{<:Integer}) = UInt[_letter_to_cpp(x) for x in v]
function _word_from_cpp(v)
    GC.@preserve v begin
        return Int[_letter_from_cpp(x) for x in v]
    end
end

_letter_to_cpp(::Type{Vector{Int}}, x::Integer) = _letter_to_cpp(x)
_letter_from_cpp(::Type{Vector{Int}}, x) = _letter_from_cpp(x)
_word_to_cpp(::Type{Vector{Int}}, w::AbstractVector{<:Integer}) = _word_to_cpp(w)
_word_from_cpp(::Type{Vector{Int}}, w) = _word_from_cpp(w)

function _ascii_string(s::AbstractString)
    value = String(s)
    isascii(value) ||
        throw(ArgumentError("string words must contain only ASCII characters"))
    return value
end

function _letter_to_cpp(::Type{String}, c::AbstractChar)
    isascii(c) || throw(ArgumentError("string letters must be ASCII characters"))
    return UInt8(c)
end

function _letter_from_cpp(::Type{String}, c)
    value = UInt8(c)
    value <= 0x7f || throw(ArgumentError("native letter is outside the ASCII alphabet"))
    return Char(value)
end

# Passing String (rather than a C string or byte vector) selects CxxWrap's
# length-aware constructor, preserving embedded NUL letters.
_word_to_cpp(::Type{String}, w::AbstractString) = StdString(_ascii_string(w))
function _word_from_cpp(::Type{String}, w)
    GC.@preserve w begin
        return _ascii_string(String(w))
    end
end

function _word_to_cpp(::Type{W}, w) where {W}
    throw(ArgumentError("expected a word with representation $W, got $(typeof(w))"))
end

function _letter_to_cpp(::Type{W}, c) where {W}
    throw(ArgumentError("letter $(repr(c)) does not match word representation $W"))
end

function _words_to_cpp(::Type{Vector{Int}}, words::AbstractVector)
    # size_t and Julia UInt have equal width but may have different C++ type
    # identities (unsigned long versus unsigned long long). Obtain the native
    # scalar type at runtime, after CxxWrap initialization, for nested vectors.
    sample = LibSemigroups.alphabet(LibSemigroups.Presentation())
    return _numeric_words_to_cpp(eltype(sample), words)
end

function _numeric_words_to_cpp(::Type{T}, words::AbstractVector) where {T}
    native_words =
        StdVector{T}[StdVector{T}(T.(_word_to_cpp(Vector{Int}, w))) for w in words]
    return StdVector{StdVector{T}}(native_words)
end

function _words_to_cpp(::Type{String}, words::AbstractVector)
    native_words = StdString[_word_to_cpp(String, w) for w in words]
    return StdVector{StdString}(native_words)
end

function _words_from_cpp(::Type{W}, words) where {W}
    GC.@preserve words begin
        return W[_word_from_cpp(W, w) for w in words]
    end
end

function _word_pairs_from_cpp(::Type{W}, flat) where {W}
    GC.@preserve flat begin
        iseven(length(flat)) ||
            throw(ArgumentError("native rule list has an unpaired word"))
        return Tuple{W,W}[
            (_word_from_cpp(W, flat[i]), _word_from_cpp(W, flat[i+1])) for
            i = 1:2:length(flat)
        ]
    end
end
