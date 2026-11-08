# Copyright (c) 2026, James W. Swent
#
# Distributed under the terms of the GPL license version 3.
# OpenAI Codex assisted with representation wrappers and string support.

"""
presentation.jl - Presentation + InversePresentation wrappers
"""

"""
    Presentation() -> Presentation{Vector{Int}}
    Presentation{String}() -> Presentation{String}
    Presentation(alphabet::AbstractString) -> Presentation{String}
    Presentation(other::Presentation) -> Presentation

Type for semigroup or monoid presentations.

This type owns a native presentation containing a vector of words (the *rules*
of the presentation), together with an *alphabet*. It is intended to be
used as the input to other algorithms in `libsemigroups` (such as
the Knuth-Bendix, Todd-Coxeter, and Kambites algorithms).

In a valid presentation, rules only consist of letters from within the
alphabet; however, for performance reasons, it is possible to update both
the rules and the alphabet independently of each other. For this reason,
it is possible for the alphabet and the rules to become out of sync.
[`Presentation`](@ref Semigroups.Presentation) provides some checks that
the rules define a valid presentation, and some related helper functions
live as module-level functions in `Semigroups`.

The zero-argument form constructs an empty presentation with no rules and
no alphabet; the one-argument form copies `other`.

`Presentation{Vector{Int}}` uses positive integer letters; `Presentation{String}`
uses literal ASCII characters. String inputs may be any `AbstractString`, and
word-valued results are owning `String` values. Characters outside ASCII are
rejected before the native call. ASCII controls, including NUL, are supported.
The empty string is the empty word, whose use is controlled by
[`set_contains_empty_word!`](@ref).

All word arguments must match the presentation's representation. Letter-valued
arguments and results use `Int` for numeric words and `Char` for string words;
positions and rule indices remain 1-based integers. This applies to all
presentation helpers, including inverse presentations. A string is a word in
literal generators, not an expression parser: `"aa"` is two occurrences of
`'a'`. Copies own independent native storage. The rule-sorting helpers
compare native letter values, rather than positions in the presentation alphabet.
"""
abstract type Presentation{W} end

mutable struct _Presentation{W,B} <: Presentation{W}
    cxx_obj::B
end

_native(p::Presentation) = p.cxx_obj
_word_type(::Presentation{W}) where {W} = W
_cxx_presentation_type(::Type{Vector{Int}}) = LibSemigroups.Presentation
_cxx_presentation_type(::Type{String}) = LibSemigroups.PresentationString

_wrap_presentation(p::LibSemigroups.Presentation) = _Presentation{Vector{Int},typeof(p)}(p)
_wrap_presentation(p::LibSemigroups.PresentationString) = _Presentation{String,typeof(p)}(p)

Presentation() = Presentation{Vector{Int}}()
Presentation{W}() where {W} = _wrap_presentation(_cxx_presentation_type(W)())
Presentation(p::Presentation{W}) where {W} =
    _wrap_presentation(_cxx_presentation_type(W)(_native(p)))
Presentation{W}(p::Presentation{W}) where {W} = Presentation(p)

function Presentation(a::AbstractString)
    p = Presentation{String}()
    return set_alphabet!(p, a)
end

function Presentation(a::AbstractVector{<:Integer})
    p = Presentation()
    return set_alphabet!(p, a)
end

Base.copy(p::Presentation) = Presentation(p)

_check_generator_capacity(::Presentation, additional::Integer = 1) = nothing
function _check_generator_capacity(p::Presentation{String}, additional::Integer = 1)
    length(alphabet(p)) + additional <= 128 ||
        throw(ArgumentError("the operation would exceed the 128-letter ASCII alphabet"))
    return nothing
end

"""
    init!(p::Presentation) -> Presentation

Remove the alphabet and all rules from `p`.

This function clears the alphabet and all rules of `p`, putting it back
into the state it would be in if it was newly constructed.
"""
init!(p::Presentation) = (LibSemigroups.init!(_native(p)); p)

"""
    alphabet(p::Presentation{W}) -> W

Return the alphabet of `p`.

Return an owning copy of the alphabet in the presentation's word representation.

# Complexity
Linear in the alphabet size, including the copy into Julia storage.
"""
alphabet(p::Presentation) =
    _word_from_cpp(_word_type(p), LibSemigroups.alphabet(_native(p)))

# Route `Base.deepcopy` through the C++ copy constructor. Default
# deepcopy_internal for CxxWrap-wrapped types may shallow-copy the handle.
Base.deepcopy_internal(p::Presentation, ::IdDict) = Presentation(p)

"""
    set_alphabet!(p::Presentation, n::Integer) -> Presentation

Set the alphabet of `p` by size.

Sets the alphabet of `p` to be the first `n` positive integers
`[1, 2, ..., n]` for numeric words. For string words, this preserves the native
3.6.1 convention of consecutive ASCII characters starting at `'a'`; `n` must
be at most 31. Supply an explicit ASCII alphabet to use a larger alphabet or
different letters.

# Arguments
- `p::Presentation`: the presentation to modify.
- `n::Integer`: the size of the alphabet.

# Throws
- `LibsemigroupsError`: if `n` is greater than the maximum number of
  letters supported.
- `ArgumentError`: if a string alphabet size exceeds 31.

# Warning
This function does not verify that the rules in `p` (if any) consist of
letters belonging to the new alphabet.

# See also
- [`throw_if_alphabet_has_duplicates`](@ref)
- [`throw_if_bad_rules`](@ref)
- [`throw_if_bad_alphabet_or_rules`](@ref)
"""
function set_alphabet!(p::Presentation, n::Integer)
    m = UInt(n)
    if _word_type(p) === String && m > 31
        throw(
            ArgumentError(
                "string alphabet sizes above 31 require an explicit ASCII alphabet",
            ),
        )
    end
    @wrap_libsemigroups_call LibSemigroups.set_alphabet_size!(_native(p), m)
    return p
end

"""
    set_alphabet!(p::Presentation, a) -> Presentation

Set the alphabet of `p` to the letters in `a`.

Sets the alphabet of `p` to the letters in `a`, preserving their order.
Use a numeric vector for numeric presentations and an ASCII string for string
presentations.

# Arguments
- `p::Presentation`: the presentation to modify.
- `a`: the alphabet.

# Throws
- `LibsemigroupsError`: if `a` contains duplicate letters.

# Warning
This function does not verify that the rules in `p` (if any) consist of
letters belonging to the new alphabet.

# See also
- [`throw_if_bad_rules`](@ref)
- [`throw_if_bad_alphabet_or_rules`](@ref)
"""
function set_alphabet!(p::Presentation, a::_WordInput)
    w = _word_to_cpp(_word_type(p), a)
    @wrap_libsemigroups_call LibSemigroups.set_alphabet!(_native(p), w)
    return p
end

"""
    alphabet_from_rules!(p::Presentation) -> Presentation

Set the alphabet of `p` to be the letters that appear in its rules.

# Complexity
At most ``O(mn)`` where ``m`` is the number of rules and ``n`` is the
length of the longest rule.

# See also
- [`throw_if_bad_rules`](@ref)
- [`throw_if_bad_alphabet_or_rules`](@ref)
"""
alphabet_from_rules!(p::Presentation) = (LibSemigroups.alphabet_from_rules!(_native(p)); p)

"""
    letter(p::Presentation, i::Integer) -> Union{Int,Char}

Return a letter in the alphabet of `p` by index.

Returns the letter of the alphabet in position `i` (1-based).

# Arguments
- `p::Presentation`: the presentation.
- `i::Integer`: the 1-based index of the letter to return.

# Throws
- `LibsemigroupsError`: if `i` is not in the range ``[1, n]``, where
  ``n`` is the length of the alphabet of `p`.
"""
function letter(p::Presentation, i::Integer)
    idx = UInt(i - 1)
    _letter_from_cpp(
        _word_type(p),
        @wrap_libsemigroups_call LibSemigroups.letter(_native(p), idx)
    )
end

"""
    index_of(p::Presentation, x::Union{Integer,AbstractChar}) -> Int

Return the index of a letter in the alphabet of `p`.

Returns the 1-based position of the letter `x` in the alphabet of `p`.

# Arguments
- `p::Presentation`: the presentation.
- `x::Union{Integer,AbstractChar}`: the letter whose index is sought.

# Throws
- `LibsemigroupsError`: if `x` does not belong to the alphabet of `p`.

# Complexity
Constant.

# Note
This function mirrors `Presentation::index` in libsemigroups, renamed to
`index_of` to avoid clashing with `Base.index`-style conventions in Julia.
"""
function index_of(p::Presentation, x::_LetterInput)
    y = _letter_to_cpp(_word_type(p), x)
    Int(@wrap_libsemigroups_call LibSemigroups.index_of(_native(p), y)) + 1
end

"""
    in_alphabet(p::Presentation, x::Union{Integer,AbstractChar}) -> Bool

Check if a letter belongs to the alphabet of `p`.

# Arguments
- `p::Presentation`: the presentation.
- `x::Union{Integer,AbstractChar}`: the letter to check.

# Complexity
Constant on average, worst case linear in the size of the alphabet.
"""
in_alphabet(p::Presentation, x::_LetterInput) =
    LibSemigroups.in_alphabet(_native(p), _letter_to_cpp(_word_type(p), x))

"""
    contains_empty_word(p::Presentation) -> Bool

Return whether the empty word is a valid relation word in `p`.

Returns `true` if the empty word is a valid relation word in `p`, and
`false` otherwise.

If `p` is not allowed to contain the empty word (according to this
function), then `p` may still be isomorphic to a monoid, but is not given
as a quotient of a free monoid.

# Complexity
Constant.
"""
contains_empty_word(p::Presentation) = LibSemigroups.contains_empty_word(_native(p))

"""
    set_contains_empty_word!(p::Presentation, val::Bool) -> Presentation

Set whether the empty word is a valid relation word in `p`.

Specify whether the empty word should be a valid relation word
(corresponding to `val` being `true`), or not (corresponding to `val`
being `false`).

If `p` is not allowed to contain the empty word (according to the value
specified here), then `p` may still be isomorphic to a monoid, but is not
given as a quotient of a free monoid.

# Arguments
- `p::Presentation`: the presentation to modify.
- `val::Bool`: whether `p` can contain the empty word.

# Complexity
Constant.
"""
set_contains_empty_word!(p::Presentation, val::Bool) =
    (LibSemigroups.set_contains_empty_word!(_native(p), val); p)

"""
    add_generator!(p::Presentation) -> Union{Int,Char}
    add_generator!(p::Presentation, x::Union{Integer,AbstractChar}) -> Presentation

Add a generator to `p`.

The zero-argument form adds the first letter not already in the alphabet
of `p` as a generator and returns the new integer letter or ASCII character.
For string presentations, automatic letters use the native human-readable
ordering and fail before mutation when all 128 ASCII characters are in use.

The one-argument form adds the letter `x` as a generator of `p`.

# Arguments
- `p::Presentation`: the presentation to modify.
- `x::Union{Integer,AbstractChar}`: (one-argument form) the letter to add as a generator.

# Throws
- `LibsemigroupsError`: (zero-argument form) if the alphabet is already
  of the maximum possible size supported by the letter type.
- `LibsemigroupsError`: (one-argument form) if `x` is already in the
  alphabet of `p`.
"""
function add_generator!(p::Presentation)
    _check_generator_capacity(p)
    x = @wrap_libsemigroups_call LibSemigroups.add_generator_no_arg!(_native(p))
    return _letter_from_cpp(_word_type(p), x)
end

function add_generator!(p::Presentation, x::_LetterInput)
    y = _letter_to_cpp(_word_type(p), x)
    @wrap_libsemigroups_call LibSemigroups.add_generator!(_native(p), y)
    return p
end

"""
    remove_generator!(p::Presentation, x::Union{Integer,AbstractChar}) -> Presentation

Remove the letter `x` as a generator of `p`.

# Arguments
- `p::Presentation`: the presentation to modify.
- `x::Union{Integer,AbstractChar}`: the letter to remove as a generator.

# Throws
- `LibsemigroupsError`: if `x` is not in the alphabet of `p`.

# Complexity
Average case: linear in the length of the alphabet; worst case: quadratic
in the length of the alphabet.
"""
function remove_generator!(p::Presentation, x::_LetterInput)
    y = _letter_to_cpp(_word_type(p), x)
    @wrap_libsemigroups_call LibSemigroups.remove_generator!(_native(p), y)
    return p
end

"""
    add_rule!(p::Presentation, lhs, rhs) -> Presentation

Add the rule `lhs = rhs` to `p`, after checking that `lhs` and `rhs`
only contain letters in the alphabet of `p`.

# Arguments
- `p::Presentation`: the presentation to modify.
- `lhs`: the left-hand side of the rule.
- `rhs`: the right-hand side of the rule.

# Throws
- `LibsemigroupsError`: if `lhs` or `rhs` contains any letters not
  belonging to the alphabet of `p`.
- `LibsemigroupsError`: if [`contains_empty_word`](@ref)`(p)` returns
  `false` and either `lhs` or `rhs` is empty.

# See also
- [`add_rule_no_checks!`](@ref)
"""
function add_rule!(p::Presentation, lhs::_WordInput, rhs::_WordInput)
    l = _word_to_cpp(_word_type(p), lhs)
    r = _word_to_cpp(_word_type(p), rhs)
    @wrap_libsemigroups_call LibSemigroups.add_rule!(_native(p), l, r)
    return p
end

"""
    add_rule_no_checks!(p::Presentation, lhs, rhs) -> Presentation

Add the rule `lhs = rhs` to `p` without checking the arguments.

# Arguments
- `p::Presentation`: the presentation to modify.
- `lhs`: the left-hand side of the rule.
- `rhs`: the right-hand side of the rule.

# Complexity
Amortized constant.

# Warning
No checks that the arguments describe words over the alphabet of `p`
are performed.

# See also
- [`add_rule!`](@ref)
"""
function add_rule_no_checks!(p::Presentation, lhs::_WordInput, rhs::_WordInput)
    l = _word_to_cpp(_word_type(p), lhs)
    r = _word_to_cpp(_word_type(p), rhs)
    LibSemigroups.add_rule_no_checks!(_native(p), l, r)
    return p
end

"""
    number_of_rules(p::Presentation) -> Int

Return the number of rules in `p`.

The rules of a [`Presentation`](@ref Semigroups.Presentation) are stored
internally as a vector of words, with each rule occupying two consecutive
entries (its left-hand and right-hand sides); the number of rules is
therefore half the length of this vector.

# Complexity
Constant.
"""
number_of_rules(p::Presentation) = Int(LibSemigroups.number_of_rules(_native(p)))

"""
    rule_lhs(p::Presentation{W}, i::Integer) -> W

Return the left-hand side of the `i`-th rule of `p` (1-based rule index).

# Arguments
- `p::Presentation`: the presentation.
- `i::Integer`: the 1-based index of the rule.

# Throws
- `LibsemigroupsError`: if `i` is not in the range ``[1, n]``, where
  ``n`` is [`number_of_rules`](@ref)`(p)`.

# See also
- [`rule_rhs`](@ref)
- [`rules`](@ref)
"""
function rule_lhs(p::Presentation, i::Integer)
    idx = UInt(i - 1)
    _word_from_cpp(
        _word_type(p),
        @wrap_libsemigroups_call LibSemigroups.rule_lhs(_native(p), idx)
    )
end

"""
    rule_rhs(p::Presentation{W}, i::Integer) -> W

Return the right-hand side of the `i`-th rule of `p` (1-based rule index).

# Arguments
- `p::Presentation`: the presentation.
- `i::Integer`: the 1-based index of the rule.

# Throws
- `LibsemigroupsError`: if `i` is not in the range ``[1, n]``, where
  ``n`` is [`number_of_rules`](@ref)`(p)`.

# See also
- [`rule_lhs`](@ref)
- [`rules`](@ref)
"""
function rule_rhs(p::Presentation, i::Integer)
    idx = UInt(i - 1)
    _word_from_cpp(
        _word_type(p),
        @wrap_libsemigroups_call LibSemigroups.rule_rhs(_native(p), idx)
    )
end

"""
    rule(p::Presentation{W}, i::Integer) -> Tuple{W,W}

Return the `i`-th rule of `p` as a `(lhs, rhs)` tuple (1-based rule index).

Thin wrapper combining [`rule_lhs`](@ref) and [`rule_rhs`](@ref). For bulk
access prefer [`rules`](@ref), which makes a single C++ call.

# Arguments
- `p::Presentation`: the presentation.
- `i::Integer`: the 1-based index of the rule.

# Throws
- `LibsemigroupsError`: if `i` is not in the range ``[1, n]``, where ``n``
  is [`number_of_rules`](@ref)`(p)`.

# See also
- [`rule_lhs`](@ref)
- [`rule_rhs`](@ref)
- [`rules`](@ref)
"""
rule(p::Presentation, i::Integer) = (rule_lhs(p, i), rule_rhs(p, i))

"""
    rules(p::Presentation{W}) -> Vector{Tuple{W,W}}

Return all rules of `p` as a vector of `(lhs, rhs)` tuples.

Mirrors `p.rules` in libsemigroups. This is a single C++ call into
`LibSemigroups.rules_vector` followed by a Julia-side pairing, so is
appreciably faster than iterating [`rule_lhs`](@ref) / [`rule_rhs`](@ref)
for large presentations.
"""
function rules(p::Presentation)
    flat = LibSemigroups.rules_vector(_native(p))
    return _word_pairs_from_cpp(_word_type(p), flat)
end

"""
    clear_rules!(p::Presentation) -> Presentation

Remove all rules from `p`.

The alphabet of `p` is left untouched.
"""
clear_rules!(p::Presentation) = (LibSemigroups.clear_rules!(_native(p)); p)

"""
    throw_if_alphabet_has_duplicates(p::Presentation)

Check if the alphabet of `p` is valid.

# Throws
- `LibsemigroupsError`: if there are duplicate letters in the alphabet
  of `p`.

# Complexity
Linear in the length of the alphabet.
"""
throw_if_alphabet_has_duplicates(p::Presentation) = (
    @wrap_libsemigroups_call LibSemigroups.throw_if_alphabet_has_duplicates(_native(p));
    nothing
)

"""
    throw_if_letter_not_in_alphabet(p::Presentation, x::Union{Integer,AbstractChar})

Check if a letter belongs to the alphabet of `p`.

# Arguments
- `p::Presentation`: the presentation.
- `x::Union{Integer,AbstractChar}`: the letter to check.

# Throws
- `LibsemigroupsError`: if `x` does not belong to the alphabet of `p`.

# Complexity
Constant on average, worst case linear in the size of the alphabet.
"""
function throw_if_letter_not_in_alphabet(p::Presentation, x::_LetterInput)
    y = _letter_to_cpp(_word_type(p), x)
    @wrap_libsemigroups_call LibSemigroups.throw_if_letter_not_in_alphabet(_native(p), y)
    return nothing
end

"""
    throw_if_bad_rules(p::Presentation)

Check if every word in every rule of `p` consists only of letters
belonging to the alphabet.

Also checks that there are an even number of words in `p`'s rule list
(i.e. that every rule has both a left- and right-hand side).

# Throws
- `LibsemigroupsError`: if any word contains a letter not in the
  alphabet of `p`.
- `LibsemigroupsError`: if the number of words in `p`'s rule list is odd.

# Complexity
Worst case ``O(mnt)`` where ``m`` is the length of the longest word,
``n`` is the size of the alphabet and ``t`` is the number of rules.
"""
throw_if_bad_rules(p::Presentation) =
    (@wrap_libsemigroups_call LibSemigroups.throw_if_bad_rules(_native(p)); nothing)

"""
    throw_if_bad_alphabet_or_rules(p::Presentation)

Check if the alphabet and rules of `p` are valid.

# Throws
- `LibsemigroupsError`: if [`throw_if_alphabet_has_duplicates`](@ref) or
  [`throw_if_bad_rules`](@ref) does.

# Complexity
Worst case ``O(mnp)`` where ``m`` is the length of the longest word,
``n`` is the size of the alphabet, and ``p`` is the number of rules.
"""
throw_if_bad_alphabet_or_rules(p::Presentation) = (
    @wrap_libsemigroups_call LibSemigroups.throw_if_bad_alphabet_or_rules(_native(p));
    nothing
)

"""
    length_of(p::Presentation) -> Int

Return the sum of the lengths of all rule words in `p`.

That is, ``\\sum (|u| + |v|)`` over all rules ``u = v`` of `p`.

This function mirrors `presentation::length` in libsemigroups. It is
named `length_of` (rather than extending `Base.length`) to avoid ambiguity
with [`number_of_rules`](@ref), since neither choice is uniformly
natural.
"""
length_of(p::Presentation) = Int(LibSemigroups.length_of(_native(p)))

"""
    longest_rule_length(p::Presentation) -> Int

Return the maximum length of a rule in `p`.

The *length* of a rule is defined to be the sum of the lengths of its
left-hand and right-hand sides.

# Throws
- `LibsemigroupsError`: if the number of rule words in `p` is odd.
"""
longest_rule_length(p::Presentation) = Int(LibSemigroups.longest_rule_length(_native(p)))

"""
    shortest_rule_length(p::Presentation) -> Int

Return the minimum length of a rule in `p`.

The *length* of a rule is defined to be the sum of the lengths of its
left-hand and right-hand sides.

# Throws
- `LibsemigroupsError`: if the number of rule words in `p` is odd.
"""
shortest_rule_length(p::Presentation) = Int(LibSemigroups.shortest_rule_length(_native(p)))

"""
    is_normalized(p::Presentation) -> Bool

Check if the presentation `p` is normalized.

Return whether the nonempty alphabet has consecutive native letter values
starting at zero. This means `[1, 2, ..., n]` for numeric words and ASCII byte
values `0x00, 0x01, ...` for string words. The empty alphabet returns `false`.

In libsemigroups 3.6.1 this predicate uses a different convention from
[`normalize_alphabet!`](@ref) for strings: the human-readable alphabet `"ab"`
produced by that operation does not satisfy this predicate.
"""
is_normalized(p::Presentation) = LibSemigroups.is_normalized(_native(p))

"""
    are_rules_sorted(p::Presentation) -> Bool

Check if the rules of `p` are sorted in short-lex order.

Returns `true` if the rules ``u_1 = v_1, \\ldots, u_n = v_n`` of `p`
satisfy ``u_1 v_1 < \\cdots < u_n v_n`` where ``<`` is the short-lex
order.

# Throws
- `LibsemigroupsError`: if the number of rule words in `p` is odd.

# See also
- [`sort_rules!`](@ref)
"""
are_rules_sorted(p::Presentation) = LibSemigroups.are_rules_sorted(_native(p))

"""
    contains_rule(p::Presentation, lhs, rhs) -> Bool

Check if `p` contains the rule `lhs = rhs`.

# Arguments
- `p::Presentation`: the presentation.
- `lhs`: the left-hand side of the rule.
- `rhs`: the right-hand side of the rule.

# Complexity
Linear in [`number_of_rules`](@ref)`(p)`.
"""
function contains_rule(p::Presentation, lhs::_WordInput, rhs::_WordInput)
    l = _word_to_cpp(_word_type(p), lhs)
    r = _word_to_cpp(_word_type(p), rhs)
    LibSemigroups.contains_rule(_native(p), l, r)
end

"""
    throw_if_odd_number_of_rules(p::Presentation)

Throw if the number of words in the rule list of `p` is odd.

# Throws
- `LibsemigroupsError`: if the number of words in the rule list of `p`
  is odd (i.e. there is a dangling left-hand side with no matching
  right-hand side).
"""
throw_if_odd_number_of_rules(p::Presentation) = (
    @wrap_libsemigroups_call LibSemigroups.throw_if_odd_number_of_rules(_native(p));
    nothing
)

"""
    normalize_alphabet!(p::Presentation) -> Presentation

Normalize the alphabet of `p`, rewriting its rules with the new letters.

Numeric alphabets become `[1, ..., n]`; string alphabets use the first `n`
letters in the native human-readable ordering. If the alphabet is already
normalized, no changes are made. For an inverse presentation, the inverse
letters are renamed together with the rules.

# Throws
- `LibsemigroupsError`: if [`throw_if_bad_alphabet_or_rules`](@ref)
  throws on `p` before modification.
"""
normalize_alphabet!(p::Presentation) =
    (@wrap_libsemigroups_call LibSemigroups.normalize_alphabet!(_native(p)); p)

"""
    change_alphabet!(p::Presentation, new_alphabet) -> Presentation

Change or re-order the alphabet of `p`.

Replaces the alphabet of `p` with `new_alphabet` where possible, and
re-writes the rules of `p` using the new alphabet. For an inverse presentation,
the inverse letters are renamed as well. A failed inverse-presentation rename
leaves the original presentation unchanged.

# Arguments
- `p::Presentation`: the presentation to modify.
- `new_alphabet`: the replacement alphabet.

# Throws
- `LibsemigroupsError`: if the size of the alphabet of `p` does not
  equal the length of `new_alphabet`.
"""
function change_alphabet!(p::Presentation, new_alphabet::_WordInput)
    w = _word_to_cpp(_word_type(p), new_alphabet)
    @wrap_libsemigroups_call LibSemigroups.change_alphabet!(_native(p), w)
    return p
end

"""
    Base.reverse!(p::Presentation) -> Presentation

Reverse every rule of `p`, in place.

Extends `Base.reverse!` so that `reverse!(p)` reverses the left- and
right-hand sides of every rule of `p`. Binding-level extensions of
`Base` functions to presentation-like types are documented on the
`Presentation` doc page.
"""
Base.reverse!(p::Presentation) = (LibSemigroups.reverse_rules!(_native(p)); p)

"""
    sort_rules!(p::Presentation) -> Presentation

Sort the rules of `p` in short-lex order.

Sorts the rules ``u_1 = v_1, \\ldots, u_n = v_n`` so that
``u_1 v_1 < \\cdots < u_n v_n`` where ``<`` is the short-lex order.

# Throws
- `LibsemigroupsError`: if the number of rule words in `p` is odd.

# See also
- [`are_rules_sorted`](@ref)
"""
sort_rules!(p::Presentation) = (LibSemigroups.sort_rules!(_native(p)); p)

"""
    sort_each_rule!(p::Presentation) -> Bool

Sort the two sides of each rule in short-lex order.

Reorders each rule ``u = v`` of `p` so that the left-hand side is
short-lex greater than or equal to the right-hand side (i.e. the longer
/ lexicographically-larger side is on the left).

Returns `true` if any rule was reordered, and `false` otherwise.

# Throws
- `LibsemigroupsError`: if the number of rule words in `p` is odd.

# Complexity
Linear in the number of rules.
"""
sort_each_rule!(p::Presentation) = LibSemigroups.sort_each_rule!(_native(p))

"""
    add_identity_rules!(p::Presentation, e::Union{Integer,AbstractChar}) -> Presentation

Add rules for an identity element.

Adds rules of the form ``ae = ea = a`` for every letter ``a`` in the
alphabet of `p`, where ``e`` is the letter given by the second argument.

# Arguments
- `p::Presentation`: the presentation to modify.
- `e::Union{Integer,AbstractChar}`: the identity element.

# Throws
- `LibsemigroupsError`: if `e` is not a letter in the alphabet of `p`.

# Complexity
Linear in the number of rules.
"""
function add_identity_rules!(p::Presentation, e::_LetterInput)
    y = _letter_to_cpp(_word_type(p), e)
    @wrap_libsemigroups_call LibSemigroups.add_identity_rules!(_native(p), y)
    return p
end

"""
    add_zero_rules!(p::Presentation, z::Union{Integer,AbstractChar}) -> Presentation

Add rules for a zero element.

Adds rules of the form ``az = za = z`` for every letter ``a`` in the
alphabet of `p`, where ``z`` is the letter given by the second argument.

# Arguments
- `p::Presentation`: the presentation to modify.
- `z::Union{Integer,AbstractChar}`: the zero element.

# Throws
- `LibsemigroupsError`: if `z` is not a letter in the alphabet of `p`.

# Complexity
Linear in the number of rules.
"""
function add_zero_rules!(p::Presentation, z::_LetterInput)
    y = _letter_to_cpp(_word_type(p), z)
    @wrap_libsemigroups_call LibSemigroups.add_zero_rules!(_native(p), y)
    return p
end

"""
    remove_duplicate_rules!(p::Presentation) -> Presentation

Remove duplicate rules from `p`.

Removes all but one instance of any duplicate rules (if any). Note that
rules of the form ``u = v`` and ``v = u`` (if any) are considered
duplicates. The rules may be reordered by this function even if there
are no duplicate rules.

# Throws
- `LibsemigroupsError`: if the number of rule words in `p` is odd.

# Complexity
Linear in the number of rules.
"""
remove_duplicate_rules!(p::Presentation) =
    (LibSemigroups.remove_duplicate_rules!(_native(p)); p)

"""
    remove_trivial_rules!(p::Presentation) -> Presentation

Remove rules consisting of identical words.

Removes all instances of rules (if any) where the left-hand side and
right-hand side are identical (i.e. rules of the form ``u = u``).

# Throws
- `LibsemigroupsError`: if the number of rule words in `p` is odd.

# Complexity
Linear in the number of rules.
"""
remove_trivial_rules!(p::Presentation) =
    (LibSemigroups.remove_trivial_rules!(_native(p)); p)

"""
    add_rules!(p::Presentation, q::Presentation) -> Presentation

Add the rules of `q` to `p`.

Each rule of `q` is checked to contain only letters of `alphabet(p)` before
being added; if the ``n``-th rule would fail this check, the first ``n-1``
rules are still added to `p`.

Mirrors `libsemigroups::presentation::add_rules`.

# Arguments
- `p::Presentation`: the presentation to add rules to.
- `q::Presentation`: the presentation whose rules should be copied into `p`.

# Throws
- `LibsemigroupsError`: if any rule of `q` contains a letter not in
  `alphabet(p)`.
"""
function add_rules!(p::Presentation, q::Presentation)
    _word_type(p) === _word_type(q) ||
        throw(ArgumentError("presentations must use the same word representation"))
    @wrap_libsemigroups_call LibSemigroups.add_rules!(_native(p), _native(q))
    return p
end

"""
    add_inverse_rules!(p::Presentation, inverses) -> Presentation
    add_inverse_rules!(p::Presentation, inverses, e::Union{Integer,AbstractChar}) -> Presentation

Add rules for inverses.

The letter with index `i` in `inverses` is taken to be the inverse of the
letter `alphabet(p)[i]`. The rules added are ``a_i b_i = e`` where
``\\{a_1, \\ldots, a_n\\}`` is `alphabet(p)`, ``\\{b_1, \\ldots, b_n\\}``
is `inverses`, and `e` is the identity letter. If `e` is omitted, the
identity is taken to be the empty word.

Mirrors `libsemigroups::presentation::add_inverse_rules`.

# Arguments
- `p::Presentation`: the presentation to add rules to.
- `inverses`: the inverses of the letters in
  `alphabet(p)`.
- `e::Union{Integer,AbstractChar}`: (3-arg form) the identity letter.

# Throws
- `LibsemigroupsError`: if `length(inverses) != length(alphabet(p))`, if
  `inverses` does not contain the same letters as `alphabet(p)`, if
  ``(a_i^{-1})^{-1} = a_i`` fails for some `i`, or if
  ``e^{-1} = e`` fails.
"""
function add_inverse_rules!(p::Presentation, inverses::_WordInput)
    v = _word_to_cpp(_word_type(p), inverses)
    @wrap_libsemigroups_call LibSemigroups.add_inverse_rules!(_native(p), v)
    return p
end

function add_inverse_rules!(p::Presentation, inverses::_WordInput, e::_LetterInput)
    v = _word_to_cpp(_word_type(p), inverses)
    y = _letter_to_cpp(_word_type(p), e)
    @wrap_libsemigroups_call LibSemigroups.add_inverse_rules_with_identity!(
        _native(p),
        v,
        y,
    )
    return p
end

"""
    replace_subword!(p::Presentation, existing, replacement) -> Presentation

Replace every non-overlapping occurrence of the word `existing` in every
rule of `p` with the word `replacement`. `p` is modified in place.

Mirrors `libsemigroups::presentation::replace_subword`.

# Arguments
- `p::Presentation`: the presentation to modify.
- `existing`: the subword to replace.
- `replacement`: the replacement word.

# Throws
- `LibsemigroupsError`: if `existing` is empty.

# See also
- [`replace_word!`](@ref)
- [`replace_word_with_new_generator!`](@ref)
"""
function replace_subword!(p::Presentation, existing::_WordInput, replacement::_WordInput)
    e = _word_to_cpp(_word_type(p), existing)
    r = _word_to_cpp(_word_type(p), replacement)
    @wrap_libsemigroups_call LibSemigroups.replace_subword!(_native(p), e, r)
    return p
end

"""
    replace_word!(p::Presentation, existing, replacement) -> Presentation

Replace every instance of the word `existing` that appears as a full side
of some rule with the word `replacement`. Specifically, every rule of the
form ``existing = w`` or ``w = existing`` has `existing` replaced by
`replacement`. `p` is modified in place.

Differs from [`replace_subword!`](@ref), which replaces any non-overlapping
occurrence of `existing` anywhere inside any rule.

Mirrors `libsemigroups::presentation::replace_word`.

# Arguments
- `p::Presentation`: the presentation to modify.
- `existing`: the word to replace.
- `replacement`: the replacement word.

# See also
- [`replace_subword!`](@ref)
"""
function replace_word!(p::Presentation, existing::_WordInput, replacement::_WordInput)
    e = _word_to_cpp(_word_type(p), existing)
    r = _word_to_cpp(_word_type(p), replacement)
    @wrap_libsemigroups_call LibSemigroups.replace_word!(_native(p), e, r)
    return p
end

"""
    replace_word_with_new_generator!(p::Presentation, w) -> Union{Int,Char}

Replace every non-overlapping (left-to-right) instance of the word `w` in
every rule of `p` with a new generator `z`, and add the rule ``z = w``.
The new generator and rule are added even if `w` is not a subword of any
rule. Return the new generator as an integer letter or ASCII character.

Mirrors `libsemigroups::presentation::replace_word_with_new_generator`.

# Arguments
- `p::Presentation`: the presentation to modify.
- `w`: the word to replace.

# Throws
- `LibsemigroupsError`: if `w` is empty.
"""
function replace_word_with_new_generator!(p::Presentation, w::_WordInput)
    _check_generator_capacity(p)
    v = _word_to_cpp(_word_type(p), w)
    z = @wrap_libsemigroups_call LibSemigroups.replace_word_with_new_generator!(
        _native(p),
        v,
    )
    return _letter_from_cpp(_word_type(p), z)
end

"""
    first_unused_letter(p::Presentation) -> Union{Int,Char}

Return the first letter not already in the alphabet of `p`. Numeric letters
use their usual order; string letters use the native human-readable order,
starting with lowercase letters, uppercase letters, and digits. String
presentations raise `ArgumentError` when all ASCII characters are in use.

Mirrors `libsemigroups::presentation::first_unused_letter`.

# Throws
- `LibsemigroupsError`: if the alphabet of `p` is already of the maximum
  possible size supported by the underlying letter type.
"""
function first_unused_letter(p::Presentation)
    _check_generator_capacity(p)
    x = @wrap_libsemigroups_call LibSemigroups.first_unused_letter(_native(p))
    return _letter_from_cpp(_word_type(p), x)
end

"""
    index_rule(p::Presentation, lhs, rhs) -> Union{Int, UndefinedType}

Return the 1-based index of the first rule of `p` equal to `lhs = rhs`,
or [`UNDEFINED`](@ref Semigroups.UNDEFINED) if no such rule exists.

Mirrors `libsemigroups::presentation::index_rule`. The returned index is
the rule-pair index - the same index accepted by [`rule_lhs`](@ref),
[`rule_rhs`](@ref), and [`rule`](@ref).

# Arguments
- `p::Presentation`: the presentation.
- `lhs`: the left-hand side of the rule.
- `rhs`: the right-hand side of the rule.

# Throws
- `LibsemigroupsError`: if [`throw_if_bad_alphabet_or_rules`](@ref) throws
  on `p`.

# See also
- [`is_rule`](@ref)
"""
function index_rule(p::Presentation, lhs::_WordInput, rhs::_WordInput)
    l = _word_to_cpp(_word_type(p), lhs)
    r = _word_to_cpp(_word_type(p), rhs)
    i = UInt(@wrap_libsemigroups_call LibSemigroups.index_rule(_native(p), l, r))
    i == typemax(UInt) && return UNDEFINED
    return div(Int(i), 2) + 1
end

"""
    is_rule(p::Presentation, lhs, rhs) -> Bool

Return `true` if `lhs = rhs` is a rule of `p`, and `false` otherwise.

Mirrors `libsemigroups::presentation::is_rule`.

# Throws
- `LibsemigroupsError`: if [`throw_if_bad_alphabet_or_rules`](@ref) throws
  on `p`.

# See also
- [`index_rule`](@ref)
"""
function is_rule(p::Presentation, lhs::_WordInput, rhs::_WordInput)
    l = _word_to_cpp(_word_type(p), lhs)
    r = _word_to_cpp(_word_type(p), rhs)
    return @wrap_libsemigroups_call LibSemigroups.is_rule(_native(p), l, r)
end

"""
    longest_rule_index(p::Presentation) -> Int

Return the 1-based index of the first rule of `p` of maximal length.

The *length* of a rule is the sum of the lengths of its left- and
right-hand sides. Mirrors `libsemigroups::presentation::longest_rule`,
returning a rule-pair index instead of the C++ iterator - so the result is
suitable to pass to [`rule`](@ref), [`rule_lhs`](@ref), or
[`rule_rhs`](@ref).

# Throws
- `LibsemigroupsError`: if the number of rule words in `p` is odd (which
  includes the case of no rules).

# See also
- [`shortest_rule_index`](@ref)
- [`longest_rule_length`](@ref)
"""
function longest_rule_index(p::Presentation)
    flat = UInt(@wrap_libsemigroups_call LibSemigroups.longest_rule_index(_native(p)))
    return div(Int(flat), 2) + 1
end

"""
    shortest_rule_index(p::Presentation) -> Int

Return the 1-based index of the first rule of `p` of minimal length.

The *length* of a rule is the sum of the lengths of its left- and
right-hand sides. Mirrors `libsemigroups::presentation::shortest_rule`,
returning a rule-pair index instead of the C++ iterator.

# Throws
- `LibsemigroupsError`: if the number of rule words in `p` is odd (which
  includes the case of no rules).

# See also
- [`longest_rule_index`](@ref)
- [`shortest_rule_length`](@ref)
"""
function shortest_rule_index(p::Presentation)
    flat = UInt(@wrap_libsemigroups_call LibSemigroups.shortest_rule_index(_native(p)))
    return div(Int(flat), 2) + 1
end

"""
    throw_if_bad_inverses(p::Presentation, inverses)

Throw a `LibsemigroupsError` if `inverses` does not define a valid list of
semigroup inverses for `alphabet(p)`.

Mirrors `libsemigroups::presentation::throw_if_bad_inverses`. Specifically,
this function checks that `alphabet(p)` and `inverses` contain the same
letters, that `inverses` is duplicate-free, and that if `a_i = b_j` (where
`a` is the alphabet and `b` is `inverses`) then `a_j = b_i` - i.e. taking
an inverse is an involution on the letters.

# Arguments
- `p::Presentation`: the presentation.
- `inverses`: the proposed inverses.

# Throws
- `LibsemigroupsError`: if any of the above conditions does not hold.
"""
function throw_if_bad_inverses(p::Presentation, inverses::_WordInput)
    v = _word_to_cpp(_word_type(p), inverses)
    @wrap_libsemigroups_call LibSemigroups.throw_if_bad_inverses(_native(p), v)
    return nothing
end

"""
    to_gap_string(p::Presentation, var_name::AbstractString = "p") -> String

Return the GAP source code that would construct a presentation with the
same alphabet and rules as `p`. Presentations in GAP are created by taking
quotients of free semigroups or monoids.

Mirrors `libsemigroups::presentation::to_gap_string`.

# Arguments
- `p::Presentation`: the presentation.
- `var_name::AbstractString`: the name of the GAP variable to assign to
  (defaults to `"p"`).

# Throws
- `LibsemigroupsError`: if `p` has more than 49 generators (the cap on
  GAP's default alphabet).
"""
function to_gap_string(p::Presentation, var_name::AbstractString = "p")
    s = @wrap_libsemigroups_call LibSemigroups.to_gap_string(_native(p), String(var_name))
    return String(s)
end

Base.:(==)(a::Presentation, b::Presentation) =
    _word_type(a) === _word_type(b) && LibSemigroups.is_equal(_native(a), _native(b))

"""
    Base.isempty(p::Presentation) -> Bool

Return `true` iff `p` has an empty alphabet and no rules - the state it
would be in immediately after [`Presentation`](@ref Semigroups.Presentation)`()`
or [`init!`](@ref).
"""
Base.isempty(p::Presentation) = isempty(alphabet(p)) && number_of_rules(p) == 0

"""
    Base.hash(p::Presentation, h::UInt) -> UInt

Stable hash suitable for dictionary keys: presentations equal under
`==` hash to the same value. The hash combines the
alphabet, rules, and the `contains_empty_word` flag.
"""
function Base.hash(p::Presentation, h::UInt)
    return hash((alphabet(p), rules(p), contains_empty_word(p)), h)
end

function Base.show(io::IO, p::Presentation)
    print(io, LibSemigroups.to_human_readable_repr(_native(p)))
end

# ----------------------------------------------------------------------------
# InversePresentation
# ----------------------------------------------------------------------------

"""
    InversePresentation(p::Presentation) -> InversePresentation
    InversePresentation(ip::InversePresentation) -> InversePresentation

Type for inverse-semigroup or inverse-monoid presentations.

An [`InversePresentation`](@ref Semigroups.InversePresentation) is a
[`Presentation`](@ref Semigroups.Presentation) together with a word
recording a semigroup inverse for each letter of the alphabet. It is a
subtype of [`Presentation`](@ref Semigroups.Presentation) and is intended
to be used as the input to other algorithms in `libsemigroups`.

Constructed from a [`Presentation`](@ref Semigroups.Presentation) (with
inverses initially empty), or as a copy of another
[`InversePresentation`](@ref Semigroups.InversePresentation).

The word representation is inherited from `p`: numeric words use integer
letters and string words use ASCII characters. The constructor does not add
inverse generators or relations; use [`to`](@ref) for that conversion.
"""
abstract type InversePresentation{W} <: Presentation{W} end

mutable struct _InversePresentation{W,B} <: InversePresentation{W}
    cxx_obj::B
end

_cxx_inverse_presentation_type(::Type{Vector{Int}}) = LibSemigroups.InversePresentation
_cxx_inverse_presentation_type(::Type{String}) = LibSemigroups.InversePresentationString

_wrap_presentation(p::LibSemigroups.InversePresentation) =
    _InversePresentation{Vector{Int},typeof(p)}(p)
_wrap_presentation(p::LibSemigroups.InversePresentationString) =
    _InversePresentation{String,typeof(p)}(p)

InversePresentation(p::Presentation{W}) where {W} =
    _wrap_presentation(_cxx_inverse_presentation_type(W)(_native(p)))
InversePresentation{W}(p::Presentation{W}) where {W} = InversePresentation(p)
Base.copy(ip::InversePresentation) = InversePresentation(ip)

"""
    init!(ip::InversePresentation) -> InversePresentation

Reset the alphabet, rules, empty-word flag, and inverse map of `ip`.
"""
function init!(ip::InversePresentation{W}) where {W}
    fresh = InversePresentation(Presentation{W}())
    ip.cxx_obj = _native(fresh)
    return ip
end

# Relabel the entire mathematical context. The native presentation helpers
# operate on the base class and cannot update InversePresentation's inverse
# map. Use a candidate so failed validation leaves the original intact.
function _rename_inverse_alphabet!(f, ip::InversePresentation{W}) where {W}
    old_inverses = inverses(ip)
    inverse_positions = Int[index_of(ip, x) for x in old_inverses]
    candidate = Base.copy(ip)
    f(candidate)
    if !isempty(old_inverses)
        new_alphabet = alphabet(candidate)
        new_inverses = if W === String
            String(UInt8[new_alphabet[i] for i in inverse_positions])
        else
            Int[new_alphabet[i] for i in inverse_positions]
        end
        set_inverses!(candidate, new_inverses)
    end
    ip.cxx_obj = _native(candidate)
    return ip
end

function change_alphabet!(ip::InversePresentation{W}, new_alphabet::_WordInput) where {W}
    native_alphabet = _word_to_cpp(W, new_alphabet)
    return _rename_inverse_alphabet!(ip) do candidate
        @wrap_libsemigroups_call LibSemigroups.change_alphabet!(
            _native(candidate),
            native_alphabet,
        )
    end
end

function normalize_alphabet!(ip::InversePresentation)
    return _rename_inverse_alphabet!(ip) do candidate
        @wrap_libsemigroups_call LibSemigroups.normalize_alphabet!(_native(candidate))
    end
end

"""
    set_inverses!(ip::InversePresentation, w) -> InversePresentation

Set the inverse of each letter in the alphabet of `ip`.

The `i`-th entry of `w` is taken to be the inverse of the `i`-th letter
of `alphabet(ip)`.

# Arguments
- `ip::InversePresentation`: the inverse presentation to modify.
- `w`: a word containing the inverses.

# Throws
- `LibsemigroupsError`: if the alphabet contains duplicate letters, or
  if `w` does not define a valid semigroup inverse for the alphabet.

# Note
Although the alphabet is not an explicit argument to this function, the
alphabet must be checked here since a specification of inverses cannot
make sense if the alphabet contains duplicate letters.

# See also
- [`throw_if_alphabet_has_duplicates`](@ref)
- [`throw_if_bad_alphabet_rules_or_inverses`](@ref)
"""
function set_inverses!(ip::InversePresentation, w::_WordInput)
    v = _word_to_cpp(_word_type(ip), w)
    @wrap_libsemigroups_call LibSemigroups.set_inverses!(_native(ip), v)
    return ip
end

"""
    inverses(ip::InversePresentation{W}) -> W

Return the inverse of each letter in the alphabet of `ip`.

The `i`-th letter of the returned word is the inverse of the `i`-th
letter of `alphabet(ip)`.
"""
inverses(ip::InversePresentation) =
    _word_from_cpp(_word_type(ip), LibSemigroups.inverses(_native(ip)))

"""
    inverse_of(ip::InversePresentation, x) -> Union{Int,Char}

Return the inverse of the letter `x` in `ip`.

# Arguments
- `ip::InversePresentation`: the inverse presentation.
- `x::Union{Integer,AbstractChar}`: the letter whose inverse is sought.

# Throws
- `LibsemigroupsError`: if no inverses have been set, if the inverse map is
  invalid for the current alphabet, or if `x` is not in the alphabet of `ip`.

The inverse map is validated before lookup, including after alphabet edits.
The presentation's rules are not checked by this operation.

# Complexity
At worst quadratic in the alphabet size to validate the inverse map.

# Note
This function mirrors `InversePresentation::inverse` in libsemigroups,
renamed to `inverse_of` to avoid shadowing Julia's `Base.inv`.
"""
function inverse_of(ip::InversePresentation, x::_LetterInput)
    y = _letter_to_cpp(_word_type(ip), x)
    inverse = @wrap_libsemigroups_call LibSemigroups.inverse_of(_native(ip), y)
    return _letter_from_cpp(_word_type(ip), inverse)
end

"""
    throw_if_bad_alphabet_rules_or_inverses(ip::InversePresentation)

Check if `ip` is a valid inverse presentation.

Specifically, checks that the alphabet of `ip` does not contain duplicate
letters, that all rules only contain letters defined in the alphabet, and
that the inverses act as semigroup inverses.

# Throws
- `LibsemigroupsError`: if the alphabet contains duplicate letters.
- `LibsemigroupsError`: if the rules contain letters not defined in the
  alphabet.
- `LibsemigroupsError`: if the inverses do not act as semigroup
  inverses.

# See also
- [`throw_if_bad_alphabet_or_rules`](@ref)
"""
throw_if_bad_alphabet_rules_or_inverses(ip::InversePresentation) = (
    @wrap_libsemigroups_call LibSemigroups.throw_if_bad_alphabet_rules_or_inverses(
        _native(ip),
    );
    nothing
)

# Equality that accounts for inverses (not the base `Presentation ==`).
Base.:(==)(a::InversePresentation, b::InversePresentation) =
    _word_type(a) === _word_type(b) && LibSemigroups.is_equal_inv(_native(a), _native(b))

# Forgetting an inverse map is an explicit Presentation(ip) conversion. In
# particular, equality must remain transitive when inverse maps differ.
Base.:(==)(::InversePresentation, ::Presentation) = false
Base.:(==)(::Presentation, ::InversePresentation) = false

function Base.hash(ip::InversePresentation, h::UInt)
    return hash(
        (
            InversePresentation,
            alphabet(ip),
            rules(ip),
            contains_empty_word(ip),
            inverses(ip),
        ),
        h,
    )
end

function Base.show(io::IO, ip::InversePresentation)
    print(io, LibSemigroups.to_human_readable_repr(_native(ip)))
end

# Extend deepcopy via the copy ctor.
Base.deepcopy_internal(ip::InversePresentation, ::IdDict) = InversePresentation(ip)
