# errors.jl - Julia wrappers for libsemigroups error handling
#
# This file provides Julia-friendly error handling that captures
# exceptions from the C++ library.

"""
    SemigroupsError <: Exception

Exception type for errors originating from libsemigroups.
"""
struct SemigroupsError <: Exception
    msg::String
end

Base.showerror(io::IO, e::SemigroupsError) = print(io, "SemigroupsError: ", e.msg)

"""
    have_error() -> Bool

Check if there are any pending errors from libsemigroups.
"""
have_error() = LibSemigroups.have_error()

"""
    get_and_clear_errors() -> String

Get all pending error messages and clear the error log.
"""
get_and_clear_errors() = LibSemigroups.get_and_clear_errors()

"""
    clear_errors!()

Clear all pending errors without retrieving them.
"""
clear_errors!() = LibSemigroups.clear_error_log()

"""
    check_error!()

Check if there are pending errors and throw a `SemigroupsError` if so.
This should be called after operations that might fail.
"""
function check_error!()
    if have_error()
        msg = get_and_clear_errors()
        throw(SemigroupsError(msg))
    end
end

"""
    @check_error expr

Execute `expr` and check for errors afterward.
Throws a `SemigroupsError` if any errors occurred.

# Example
```julia
@check_error begin
    # code that might cause errors
end
```
"""
macro check_error(expr)
    quote
        result = $(esc(expr))
        check_error!()
        result
    end
end
