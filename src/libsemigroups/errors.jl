# errors.jl - Error handling utilities for libsemigroups
#
# This module provides utilities for translating C++ exceptions from libsemigroups
# into idiomatic Julia errors with proper 1-based indexing.

"""
    Errors

Module for translating libsemigroups C++ exceptions into idiomatic Julia errors.
"""
module Errors

export translate_libsemigroups_error, @wrap_libsemigroups_call

# ============================================================================
# Regex patterns for libsemigroups error messages
# ============================================================================

# Strip prefix: "filename:line:func: message" -> "message"
const MESSAGE_PREFIX_REGEX = r"^[^:]+:\d+:[^:]+:\s*(.*)$"

# Bounds: "image value out of bounds, expected value in [0, 3), found 5 in position 2"
const BOUNDS_PATTERN =
    r"(\w+)\s+value\s+out\s+of\s+bounds,\s+expected\s+value\s+in\s+\[0,\s*(\d+)\),\s+found\s+(\d+)\s+in\s+position\s+(\d+)"

# Duplicates: "duplicate image value, found 2 in position 3, first occurrence in position 1"
const DUPLICATE_PATTERN =
    r"duplicate\s+(\w+)\s+value,\s+found\s+(\d+)\s+in\s+position\s+(\d+),\s+first\s+occurrence\s+in\s+position\s+(\d+)"

# Size mismatch: "domain and image size mismatch, domain has size 5 but image has size 3"
const SIZE_MISMATCH_PATTERN =
    r"(\w+)\s+and\s+(\w+)\s+size\s+mismatch.*has\s+size\s+(\d+).*has\s+size\s+(\d+)"

# UNDEFINED: "must not contain UNDEFINED...in position 2"
const UNDEFINED_PATTERN = r"must\s+not\s+contain\s+UNDEFINED.*in\s+position\s+(\d+)"

# ============================================================================
# Helper functions
# ============================================================================

"""
    extract_message(full_message::AbstractString) -> String

Strip the libsemigroups prefix (filename:line:function:) from error messages.
"""
function extract_message(full_message::AbstractString)
    m = match(MESSAGE_PREFIX_REGEX, full_message)
    if m !== nothing
        return String(m.captures[1])
    end
    return String(full_message)
end

"""
    adjust_index(idx::Integer) -> Int

Convert 0-based index to 1-based index for Julia.
"""
adjust_index(idx::Integer) = Int(idx) + 1

"""
    adjust_bounds(lower::Integer, upper::Integer) -> Tuple{Int, Int}

Convert 0-based bounds [lower, upper) to 1-based bounds [lower+1, upper+1).
"""
adjust_bounds(lower::Integer, upper::Integer) = (adjust_index(lower), adjust_index(upper))

# ============================================================================
# Error translation functions
# ============================================================================

"""
    translate_bounds_error(msg::AbstractString) -> Union{DomainError, Nothing}

Translate a bounds error message to a DomainError with 1-based indexing.
"""
function translate_bounds_error(msg::AbstractString)
    m = match(BOUNDS_PATTERN, msg)
    if m === nothing
        return nothing
    end

    value_type = m.captures[1]  # e.g., "image" or "domain"
    upper_bound = parse(Int, m.captures[2])  # 0-based upper bound
    found_value = parse(Int, m.captures[3])  # 0-based value found
    position = parse(Int, m.captures[4])  # 0-based position

    # Convert to 1-based
    found_value_1based = found_value + 1
    position_1based = position + 1
    lower_1based, upper_1based = adjust_bounds(0, upper_bound)

    error_msg =
        "$value_type value out of bounds at position $position_1based, " *
        "expected value in [$lower_1based, $upper_1based)"

    return DomainError(found_value_1based, error_msg)
end

"""
    translate_duplicate_error(msg::AbstractString) -> Union{ArgumentError, Nothing}

Translate a duplicate value error message to an ArgumentError with 1-based indexing.
"""
function translate_duplicate_error(msg::AbstractString)
    m = match(DUPLICATE_PATTERN, msg)
    if m === nothing
        return nothing
    end

    value_type = m.captures[1]  # e.g., "image" or "domain"
    found_value = parse(Int, m.captures[2])  # 0-based value
    position = parse(Int, m.captures[3])  # 0-based position
    first_pos = parse(Int, m.captures[4])  # 0-based first occurrence

    # Convert to 1-based
    found_value_1based = found_value + 1
    position_1based = position + 1
    first_pos_1based = first_pos + 1

    error_msg =
        "duplicate $value_type value $found_value_1based at position $position_1based, " *
        "first occurrence at position $first_pos_1based"

    return ArgumentError(error_msg)
end

"""
    translate_size_mismatch_error(msg::AbstractString) -> Union{DimensionMismatch, Nothing}

Translate a size mismatch error message to a DimensionMismatch.
"""
function translate_size_mismatch_error(msg::AbstractString)
    m = match(SIZE_MISMATCH_PATTERN, msg)
    if m === nothing
        return nothing
    end

    first_name = m.captures[1]  # e.g., "domain"
    second_name = m.captures[2]  # e.g., "image"
    first_size = parse(Int, m.captures[3])
    second_size = parse(Int, m.captures[4])

    error_msg =
        "$first_name and $second_name size mismatch: " *
        "$first_name has size $first_size but $second_name has size $second_size"

    return DimensionMismatch(error_msg)
end

"""
    translate_undefined_error(msg::AbstractString) -> Union{ArgumentError, Nothing}

Translate an UNDEFINED error message to an ArgumentError with 1-based indexing.
"""
function translate_undefined_error(msg::AbstractString)
    m = match(UNDEFINED_PATTERN, msg)
    if m === nothing
        return nothing
    end

    position = parse(Int, m.captures[1])  # 0-based position
    position_1based = position + 1

    error_msg = "must not contain UNDEFINED in position $position_1based"

    return ArgumentError(error_msg)
end

"""
    translate_libsemigroups_error(ex::Exception) -> Exception

Translate a libsemigroups C++ exception into an idiomatic Julia error.

Returns the appropriate Julia error type (DomainError, ArgumentError,
DimensionMismatch) with 1-based indexing, or returns the original
exception if it cannot be translated.
"""
function translate_libsemigroups_error(ex::Exception)
    msg = string(ex)
    clean_msg = extract_message(msg)

    # Try each translation in order of specificity
    translated = translate_bounds_error(clean_msg)
    translated !== nothing && return translated

    translated = translate_duplicate_error(clean_msg)
    translated !== nothing && return translated

    translated = translate_size_mismatch_error(clean_msg)
    translated !== nothing && return translated

    translated = translate_undefined_error(clean_msg)
    translated !== nothing && return translated

    # Fallback: return ArgumentError with cleaned message
    return ArgumentError(clean_msg)
end

"""
    @wrap_libsemigroups_call(expr)

Wrap a libsemigroups C++ call to translate exceptions into idiomatic Julia errors.

# Example
```julia
cxx_obj = @wrap_libsemigroups_call begin
    CxxType(StdVector(images_typed))
end
```
"""
macro wrap_libsemigroups_call(expr)
    return quote
        try
            $(esc(expr))
        catch ex
            throw(translate_libsemigroups_error(ex))
        end
    end
end

end # module Errors
