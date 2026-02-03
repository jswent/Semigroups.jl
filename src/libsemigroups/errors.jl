# errors.jl - Error handling utilities for libsemigroups
#
# This module provides utilities for catching C++ exceptions from libsemigroups
# and rethrowing them as a Julia-native LibsemigroupsError with the C++ file/line
# prefix stripped.

"""
    Errors

Module for wrapping libsemigroups C++ exceptions as `LibsemigroupsError`.
"""
module Errors

export LibsemigroupsError, @wrap_libsemigroups_call

# ============================================================================
# Regex patterns
# ============================================================================

# Strip prefix: "filename:line:func: message" -> "message"
const MESSAGE_PREFIX_REGEX = r"^[^:]+:\d+:[^:]+:\s*(.*)$"

# ============================================================================
# LibsemigroupsError
# ============================================================================

"""
    LibsemigroupsError <: Exception

Exception type for errors originating from the libsemigroups C++ library.
The error message has the C++ source location prefix stripped but is otherwise
unchanged (including 0-based indexing).
"""
struct LibsemigroupsError <: Exception
    msg::String
end

Base.showerror(io::IO, e::LibsemigroupsError) = print(io, "LibsemigroupsError: ", e.msg)

# ============================================================================
# Helper functions
# ============================================================================

"""
    exception_message(ex::Exception) -> String

Extract the raw message string from an exception.
"""
exception_message(ex::ErrorException) = ex.msg
exception_message(ex::Exception) = sprint(showerror, ex)

"""
    extract_message(full_message::AbstractString) -> String

Extract the libsemigroups error message from a potentially multi-line C++ exception.

CxxWrap exceptions may contain a full C++ stack trace with the actual error message
on the last line in the format "filename:line:function: message". This function
finds that line and strips the prefix, returning only the message.
"""
function extract_message(full_message::AbstractString)
    # Try the last line first (CxxWrap multi-line stack traces put the message there)
    lines = split(rstrip(full_message), '\n')
    for line in Iterators.reverse(lines)
        m = match(MESSAGE_PREFIX_REGEX, line)
        if m !== nothing
            return String(m.captures[1])
        end
    end
    return String(full_message)
end

# ============================================================================
# Macro
# ============================================================================

"""
    @wrap_libsemigroups_call(expr)

Wrap a libsemigroups C++ call to catch exceptions and rethrow them as
`LibsemigroupsError` with the C++ prefix stripped.

# Example
```julia
cxx_obj = @wrap_libsemigroups_call begin
    CxxType(StdVector(images_typed))
end
```
"""
macro wrap_libsemigroups_call(expr)
    return quote
        local result
        local caught_ex = nothing
        try
            result = $(esc(expr))
        catch ex
            if parentmodule(Errors).is_debug()
                # Throw inside catch block to show both error and full C++ trace
                throw(LibsemigroupsError(extract_message(exception_message(ex))))
            end
            caught_ex = ex
        end
        # Throw outside catch block to avoid exception chaining ("caused by")
        if caught_ex !== nothing
            throw(LibsemigroupsError(extract_message(exception_message(caught_ex))))
        end
        result
    end
end

end # module Errors
